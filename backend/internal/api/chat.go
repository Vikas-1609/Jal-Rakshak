package api

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"jalrakshak/backend/internal/catchment"
	"jalrakshak/backend/internal/gemini"
)

// Limits on a chat request, so one client can't send a huge prompt.
const (
	maxChatTurns    = 20
	maxChatMsgLen   = 1000 // per user question, in characters
	maxChatReplyLen = 4000 // per earlier Gemini reply sent back as history
	chatBodyMaxLen  = 64 << 10
)

type chatRequest struct {
	Lang     string               `json:"lang"`
	Messages []gemini.ChatMessage `json:"messages"`
}

// chatInput reads and checks a chat request, writing a 4xx if it is invalid.
// Body: {"lang": "en", "messages": [{"role": "user", "text": "..."}, ...]}
// The whole conversation is sent each time (the server keeps no history);
// it must end with the user's new question.
func (s *Server) chatInput(w http.ResponseWriter, r *http.Request) (*catchment.Lake, *catchment.Zone, chatRequest, bool) {
	var req chatRequest
	l, z, ok := s.zoneOf(w, r)
	if !ok {
		return nil, nil, req, false
	}
	r.Body = http.MaxBytesReader(w, r.Body, chatBodyMaxLen)
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON body")
		return nil, nil, req, false
	}
	if req.Lang == "" {
		req.Lang = "en"
	}
	if !gemini.SupportedLang(req.Lang) {
		writeError(w, http.StatusBadRequest, "lang must be en or hi")
		return nil, nil, req, false
	}
	if msg := checkChat(req.Messages); msg != "" {
		writeError(w, http.StatusBadRequest, msg)
		return nil, nil, req, false
	}
	return l, z, req, true
}

// chatStream answers as Server-Sent Events while Gemini writes:
//
//	data: {"text": "piece of the answer"}   (repeated)
//	data: {"done": true}                     (finished)
//	data: {"error": "chat unavailable"}      (failed part-way)
//
// Errors before the stream starts are ordinary JSON responses, as in chat.
func (s *Server) chatStream(w http.ResponseWriter, r *http.Request) {
	l, z, req, ok := s.chatInput(w, r)
	if !ok {
		return
	}
	flusher, ok := w.(http.Flusher)
	if !ok {
		writeError(w, http.StatusInternalServerError, "streaming unsupported")
		return
	}
	if !s.ex.Enabled() {
		writeError(w, http.StatusServiceUnavailable, "chat needs Gemini, which is not configured")
		return
	}

	w.Header().Set("Content-Type", "text/event-stream; charset=utf-8")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("X-Accel-Buffering", "no") // proxies: don't hold events back
	w.WriteHeader(http.StatusOK)
	send := func(event map[string]any) error {
		b, _ := json.Marshal(event)
		if _, err := fmt.Fprintf(w, "data: %s\n\n", b); err != nil {
			return err
		}
		flusher.Flush()
		return nil
	}

	ctx, cancel := context.WithTimeout(r.Context(), 60*time.Second)
	defer cancel()
	err := s.ex.ChatStream(ctx, l, z, req.Lang, req.Messages, func(text string) error {
		return send(map[string]any{"text": text})
	})
	if err != nil {
		if r.Context().Err() == nil { // not just the client leaving
			log.Printf("chat stream %s/%s/%s: %v", l.ID, z.ID, req.Lang, err)
			send(map[string]any{"error": "chat unavailable"})
		}
		return
	}
	send(map[string]any{"done": true})
}

// chat answers in one JSON response: {"reply": "..."}.
func (s *Server) chat(w http.ResponseWriter, r *http.Request) {
	l, z, req, ok := s.chatInput(w, r)
	if !ok {
		return
	}
	ctx, cancel := context.WithTimeout(r.Context(), 45*time.Second)
	defer cancel()
	reply, err := s.ex.Chat(ctx, l, z, req.Lang, req.Messages)
	if errors.Is(err, gemini.ErrNoGemini) {
		writeError(w, http.StatusServiceUnavailable, "chat needs Gemini, which is not configured")
		return
	}
	if err != nil {
		log.Printf("chat %s/%s/%s: %v", l.ID, z.ID, req.Lang, err)
		writeError(w, http.StatusBadGateway, "chat unavailable")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"reply": reply})
}

// checkChat returns why a conversation is invalid, or "" if it is fine.
func checkChat(msgs []gemini.ChatMessage) string {
	if len(msgs) == 0 || len(msgs) > maxChatTurns {
		return fmt.Sprintf("messages must hold 1 to %d turns", maxChatTurns)
	}
	for i, m := range msgs {
		limit := maxChatMsgLen
		switch m.Role {
		case "user":
		case "model":
			limit = maxChatReplyLen
		default:
			return "role must be user or model"
		}
		if strings.TrimSpace(m.Text) == "" || len([]rune(m.Text)) > limit {
			return fmt.Sprintf("message %d must be 1 to %d characters", i+1, limit)
		}
	}
	if msgs[len(msgs)-1].Role != "user" {
		return "the last message must be from the user"
	}
	return ""
}
