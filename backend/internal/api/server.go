// JalRakshak backend: serves catchment zones for several Aravalli lakes,
// runs the intervention simulator, and asks Gemini to explain each zone.
//
//	GET  /api/lakes                               every lake with its totals
//	GET  /api/lakes/{lake}/summary                one lake's totals
//	GET  /api/lakes/{lake}/zones                  zone GeoJSON for the map
//	GET  /api/lakes/{lake}/zones/{id}             one zone's fields
//	GET  /api/lakes/{lake}/zones/{id}/explain     Gemini explanation (?lang=en|hi)
//	POST /api/lakes/{lake}/zones/{id}/chat        Gemini answer to a follow-up question
//	POST /api/lakes/{lake}/zones/{id}/chat/stream the same, streamed as Server-Sent Events
//	POST /api/lakes/{lake}/simulate               tonnes saved for a set of fixes
//
// Run with -pregen to generate every explanation into data/explanations.json,
// which is embedded as a fallback if Gemini is unreachable during the demo.
package main

import (
	"context"
	"embed"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"google.golang.org/genai"
)

//go:embed data
var dataFS embed.FS

func main() {
	pregen := flag.Bool("pregen", false, "generate all explanations into data/explanations.json and exit")
	flag.Parse()

	if err := loadDotEnv(".env"); err != nil {
		log.Fatalf("read .env: %v", err)
	}

	region, err := loadEmbeddedRegion()
	if err != nil {
		log.Fatal(err)
	}

	ex := &Explainer{
		models:   geminiModels(),
		fallback: map[string]Explanation{},
		cache:    map[string]Explanation{},
	}
	if b, err := dataFS.ReadFile("data/explanations.json"); err == nil {
		if err := json.Unmarshal(b, &ex.fallback); err != nil {
			log.Fatalf("parse data/explanations.json: %v", err)
		}
	}
	// The client reads GEMINI_API_KEY, or uses Vertex AI if GOOGLE_GENAI_USE_VERTEXAI=true.
	if client, err := genai.NewClient(context.Background(), nil); err != nil {
		log.Printf("Gemini disabled (%v); serving %d saved explanations only", err, len(ex.fallback))
	} else {
		ex.client = client
	}

	if *pregen {
		if err := pregenerate(ex, region); err != nil {
			log.Fatal(err)
		}
		return
	}

	srv := &server{region: region, ex: ex}
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) { w.Write([]byte("ok")) })
	mux.HandleFunc("GET /api/lakes", srv.lakes)
	mux.HandleFunc("GET /api/lakes/{lake}/summary", srv.summary)
	mux.HandleFunc("GET /api/lakes/{lake}/zones", srv.zones)
	mux.HandleFunc("GET /api/lakes/{lake}/zones/{id}", srv.zone)
	mux.HandleFunc("GET /api/lakes/{lake}/zones/{id}/explain", srv.explain)
	mux.HandleFunc("POST /api/lakes/{lake}/zones/{id}/chat", srv.chat)
	mux.HandleFunc("POST /api/lakes/{lake}/zones/{id}/chat/stream", srv.chatStream)
	mux.HandleFunc("POST /api/lakes/{lake}/simulate", srv.simulate)

	addr := ":" + envOr("PORT", "8080")
	log.Printf("JalRakshak API on %s (%d lakes, models %s)", addr, len(region.Lakes), strings.Join(ex.models, " > "))
	// Inside cors, so preflight OPTIONS requests aren't logged.
	log.Fatal(http.ListenAndServe(addr, cors(logRequests(mux))))
}

func loadEmbeddedRegion() (*Region, error) {
	geojson, err := dataFS.ReadFile("data/zones.geojson")
	if err != nil {
		return nil, err
	}
	lakes, err := dataFS.ReadFile("data/lakes.json")
	if err != nil {
		return nil, err
	}
	return loadRegion(geojson, lakes)
}

type server struct {
	region *Region
	ex     *Explainer
}

// lake resolves {lake} from the path, writing a 404 if it is unknown.
func (s *server) lake(w http.ResponseWriter, r *http.Request) (*Lake, bool) {
	l, ok := s.region.ByID[r.PathValue("lake")]
	if !ok {
		writeError(w, http.StatusNotFound, "unknown lake")
	}
	return l, ok
}

// zoneOf resolves {lake} and {id} from the path, writing a 404 if either is unknown.
func (s *server) zoneOf(w http.ResponseWriter, r *http.Request) (*Lake, *Zone, bool) {
	l, ok := s.lake(w, r)
	if !ok {
		return nil, nil, false
	}
	z, ok := l.ByID[r.PathValue("id")]
	if !ok {
		writeError(w, http.StatusNotFound, "unknown zone")
	}
	return l, z, ok
}

func (s *server) lakes(w http.ResponseWriter, r *http.Request) {
	rows := make([]LakeSummary, 0, len(s.region.Lakes))
	for _, l := range s.region.Lakes {
		rows = append(rows, l.summaryRow())
	}
	writeJSON(w, http.StatusOK, rows)
}

func (s *server) summary(w http.ResponseWriter, r *http.Request) {
	if l, ok := s.lake(w, r); ok {
		writeJSON(w, http.StatusOK, l.summaryRow())
	}
}

func (s *server) zones(w http.ResponseWriter, r *http.Request) {
	l, ok := s.lake(w, r)
	if !ok {
		return
	}
	w.Header().Set("Content-Type", "application/geo+json")
	w.Header().Set("Cache-Control", "public, max-age=3600")
	w.Write(l.GeoJSON)
}

func (s *server) zone(w http.ResponseWriter, r *http.Request) {
	if _, z, ok := s.zoneOf(w, r); ok {
		writeJSON(w, http.StatusOK, z)
	}
}

func (s *server) explain(w http.ResponseWriter, r *http.Request) {
	l, z, ok := s.zoneOf(w, r)
	if !ok {
		return
	}
	lang := r.URL.Query().Get("lang")
	if lang == "" {
		lang = "en"
	}
	if _, ok := langNames[lang]; !ok {
		writeError(w, http.StatusBadRequest, "lang must be en or hi")
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 45*time.Second)
	defer cancel()
	exp, source, err := s.ex.explain(ctx, l, z, lang)
	if err != nil {
		log.Printf("explain %s/%s/%s: %v", l.ID, z.ID, lang, err)
		writeError(w, http.StatusBadGateway, "explanation unavailable")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"lake_id":     l.ID,
		"zone_id":     z.ID,
		"lang":        lang,
		"source":      source,
		"explanation": exp,
	})
}

// Limits on a chat request, so one client can't send a huge prompt.
const (
	maxChatTurns    = 20
	maxChatMsgLen   = 1000 // per user question, in characters
	maxChatReplyLen = 4000 // per earlier Gemini reply sent back as history
	chatBodyMaxLen  = 64 << 10
)

type chatRequest struct {
	Lang     string        `json:"lang"`
	Messages []ChatMessage `json:"messages"`
}

// chatInput reads and checks a chat request, writing a 4xx if it is invalid.
// Body: {"lang": "en", "messages": [{"role": "user", "text": "..."}, ...]}
// The whole conversation is sent each time (the server keeps no history);
// it must end with the user's new question.
func (s *server) chatInput(w http.ResponseWriter, r *http.Request) (*Lake, *Zone, chatRequest, bool) {
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
	if _, ok := langNames[req.Lang]; !ok {
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
func (s *server) chatStream(w http.ResponseWriter, r *http.Request) {
	l, z, req, ok := s.chatInput(w, r)
	if !ok {
		return
	}
	flusher, ok := w.(http.Flusher)
	if !ok {
		writeError(w, http.StatusInternalServerError, "streaming unsupported")
		return
	}
	if s.ex.client == nil {
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
	err := s.ex.chatStream(ctx, l, z, req.Lang, req.Messages, func(text string) error {
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
func (s *server) chat(w http.ResponseWriter, r *http.Request) {
	l, z, req, ok := s.chatInput(w, r)
	if !ok {
		return
	}
	ctx, cancel := context.WithTimeout(r.Context(), 45*time.Second)
	defer cancel()
	reply, err := s.ex.chat(ctx, l, z, req.Lang, req.Messages)
	if errors.Is(err, errNoGemini) {
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
func checkChat(msgs []ChatMessage) string {
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

// simulate body: {"all": {...fixes}, "zones": {"Z14": {...fixes}}}
// "all" applies to every zone; entries in "zones" override it per zone.
func (s *server) simulate(w http.ResponseWriter, r *http.Request) {
	l, ok := s.lake(w, r)
	if !ok {
		return
	}
	var req struct {
		All   *Fixes           `json:"all"`
		Zones map[string]Fixes `json:"zones"`
	}
	r.Body = http.MaxBytesReader(w, r.Body, 64<<10)
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON body")
		return
	}

	fixes := map[string]Fixes{}
	if req.All != nil {
		for _, z := range l.Zones {
			fixes[z.ID] = *req.All
		}
	}
	for id, f := range req.Zones {
		if _, ok := l.ByID[id]; !ok {
			writeError(w, http.StatusBadRequest, "unknown zone "+id)
			return
		}
		fixes[id] = f
	}
	writeJSON(w, http.StatusOK, l.simulate(fixes))
}

func pregenerate(ex *Explainer, region *Region) error {
	if ex.client == nil {
		return fmt.Errorf("set GEMINI_API_KEY to pregenerate")
	}
	out := map[string]Explanation{}
	for _, l := range region.Lakes {
		for _, z := range l.Zones {
			for lang := range langNames {
				var exp Explanation
				var err error
				for attempt := 1; attempt <= 3; attempt++ {
					ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
					exp, err = ex.generate(ctx, l, z, lang)
					cancel()
					if err == nil {
						break
					}
					log.Printf("%s/%s/%s attempt %d: %v", l.ID, z.ID, lang, attempt, err)
					time.Sleep(time.Duration(attempt) * 10 * time.Second) // back off for rate limits
				}
				if err != nil {
					return fmt.Errorf("%s/%s/%s: %w", l.ID, z.ID, lang, err)
				}
				out[cacheKey(l.ID, z.ID, lang)] = exp
				log.Printf("%s/%s/%s: %s", l.ID, z.ID, lang, exp.Headline)
			}
		}
	}
	b, err := json.MarshalIndent(out, "", "  ")
	if err != nil {
		return err
	}
	if err := os.WriteFile("data/explanations.json", b, 0o644); err != nil {
		return err
	}
	log.Printf("wrote %d explanations to data/explanations.json; rebuild to embed them", len(out))
	return nil
}

func cors(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", envOr("ALLOWED_ORIGIN", "*"))
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

// logRequests prints one line per request: method, path, status and time
// taken. Health checks are skipped; Cloud Run probes them constantly.
func logRequests(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rec := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
		next.ServeHTTP(rec, r)
		if r.URL.Path != "/healthz" {
			log.Printf("%s %s %d %s", r.Method, r.URL.RequestURI(), rec.status, time.Since(start).Round(time.Millisecond))
		}
	})
}

// statusRecorder remembers the response status for logging.
type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (s *statusRecorder) WriteHeader(code int) {
	s.status = code
	s.ResponseWriter.WriteHeader(code)
}

// Flush passes through, so streamed chat answers still arrive piece by piece.
func (s *statusRecorder) Flush() {
	if f, ok := s.ResponseWriter.(http.Flusher); ok {
		f.Flush()
	}
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v)
}

func writeError(w http.ResponseWriter, status int, msg string) {
	writeJSON(w, status, map[string]string{"error": msg})
}

// defaultModels are tried in order. Each has its own daily quota on the free
// tier, so a later one keeps the app working when an earlier one runs out.
// Flash-Lite first: 2–5 s per explanation against 20–40 s for 3.5 Flash,
// with the same numbers (they are precomputed; the model only words them).
const defaultModels = "gemini-3.1-flash-lite,gemini-3.5-flash,gemini-3-flash-preview"

// geminiModels reads GEMINI_MODELS (comma-separated, first is preferred).
// GEMINI_MODEL, the older single-model setting, still works.
func geminiModels() []string {
	list := envOr("GEMINI_MODELS", envOr("GEMINI_MODEL", defaultModels))
	var models []string
	for _, m := range strings.Split(list, ",") {
		if m = strings.TrimSpace(m); m != "" {
			models = append(models, m)
		}
	}
	return models
}

func envOr(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}
