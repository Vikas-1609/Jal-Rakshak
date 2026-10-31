package api

import (
	"jalrakshak/backend/internal/gemini"
	"strings"
	"testing"
)

func TestCheckChat(t *testing.T) {
	user := gemini.ChatMessage{Role: "user", Text: "Where should we start?"}
	model := gemini.ChatMessage{Role: "model", Text: "Start with contour bunds."}
	many := make([]gemini.ChatMessage, maxChatTurns+1)
	for i := range many {
		many[i] = user
	}

	tests := []struct {
		name string
		msgs []gemini.ChatMessage
		ok   bool
	}{
		{"one question", []gemini.ChatMessage{user}, true},
		{"follow-up", []gemini.ChatMessage{user, model, user}, true},
		{"empty", nil, false},
		{"too many turns", many, false},
		{"ends with model", []gemini.ChatMessage{user, model}, false},
		{"bad role", []gemini.ChatMessage{{Role: "system", Text: "hi"}}, false},
		{"blank text", []gemini.ChatMessage{{Role: "user", Text: "  "}}, false},
		{"too long", []gemini.ChatMessage{{Role: "user", Text: strings.Repeat("a", maxChatMsgLen+1)}}, false},
		{"long reply ok", []gemini.ChatMessage{{Role: "model", Text: strings.Repeat("a", maxChatMsgLen+1)}, user}, true},
		// Hindi is counted in characters, not bytes.
		{"long hindi ok", []gemini.ChatMessage{{Role: "user", Text: strings.Repeat("क", maxChatMsgLen)}}, true},
	}
	for _, tt := range tests {
		if got := checkChat(tt.msgs) == ""; got != tt.ok {
			t.Errorf("%s: ok = %v, want %v (%q)", tt.name, got, tt.ok, checkChat(tt.msgs))
		}
	}
}
