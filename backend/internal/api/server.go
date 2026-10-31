// Package api is the HTTP layer: routes, request checks and JSON responses.
//
//	GET  /api/lakes                               every lake with its totals
//	GET  /api/lakes/{lake}/summary                one lake's totals
//	GET  /api/lakes/{lake}/zones                  zone GeoJSON for the map
//	GET  /api/lakes/{lake}/zones/{id}             one zone's fields
//	GET  /api/lakes/{lake}/zones/{id}/explain     Gemini explanation (?lang=en|hi)
//	POST /api/lakes/{lake}/zones/{id}/chat        Gemini answer to a follow-up question
//	POST /api/lakes/{lake}/zones/{id}/chat/stream the same, streamed as Server-Sent Events
//	POST /api/lakes/{lake}/simulate               tonnes saved for a set of fixes
package api

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"time"

	"jalrakshak/backend/internal/catchment"
	"jalrakshak/backend/internal/gemini"
)

// Server answers API requests from the region's data and the explainer.
type Server struct {
	region *catchment.Region
	ex     *gemini.Explainer
}

func New(region *catchment.Region, ex *gemini.Explainer) *Server {
	return &Server{region: region, ex: ex}
}

// Handler returns every route, wrapped in CORS and request logging.
func (s *Server) Handler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) { w.Write([]byte("ok")) })
	mux.HandleFunc("GET /api/lakes", s.lakes)
	mux.HandleFunc("GET /api/lakes/{lake}/summary", s.summary)
	mux.HandleFunc("GET /api/lakes/{lake}/zones", s.zones)
	mux.HandleFunc("GET /api/lakes/{lake}/zones/{id}", s.zone)
	mux.HandleFunc("GET /api/lakes/{lake}/zones/{id}/explain", s.explain)
	mux.HandleFunc("POST /api/lakes/{lake}/zones/{id}/chat", s.chat)
	mux.HandleFunc("POST /api/lakes/{lake}/zones/{id}/chat/stream", s.chatStream)
	mux.HandleFunc("POST /api/lakes/{lake}/simulate", s.simulate)
	// Inside cors, so preflight OPTIONS requests aren't logged.
	return cors(logRequests(mux))
}

// lake resolves {lake} from the path, writing a 404 if it is unknown.
func (s *Server) lake(w http.ResponseWriter, r *http.Request) (*catchment.Lake, bool) {
	l, ok := s.region.ByID[r.PathValue("lake")]
	if !ok {
		writeError(w, http.StatusNotFound, "unknown lake")
	}
	return l, ok
}

// zoneOf resolves {lake} and {id} from the path, writing a 404 if either is unknown.
func (s *Server) zoneOf(w http.ResponseWriter, r *http.Request) (*catchment.Lake, *catchment.Zone, bool) {
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

func (s *Server) lakes(w http.ResponseWriter, r *http.Request) {
	rows := make([]catchment.LakeSummary, 0, len(s.region.Lakes))
	for _, l := range s.region.Lakes {
		rows = append(rows, l.SummaryRow())
	}
	writeJSON(w, http.StatusOK, rows)
}

func (s *Server) summary(w http.ResponseWriter, r *http.Request) {
	if l, ok := s.lake(w, r); ok {
		writeJSON(w, http.StatusOK, l.SummaryRow())
	}
}

func (s *Server) zones(w http.ResponseWriter, r *http.Request) {
	l, ok := s.lake(w, r)
	if !ok {
		return
	}
	w.Header().Set("Content-Type", "application/geo+json")
	w.Header().Set("Cache-Control", "public, max-age=3600")
	w.Write(l.GeoJSON)
}

func (s *Server) zone(w http.ResponseWriter, r *http.Request) {
	if _, z, ok := s.zoneOf(w, r); ok {
		writeJSON(w, http.StatusOK, z)
	}
}

func (s *Server) explain(w http.ResponseWriter, r *http.Request) {
	l, z, ok := s.zoneOf(w, r)
	if !ok {
		return
	}
	lang := r.URL.Query().Get("lang")
	if lang == "" {
		lang = "en"
	}
	if !gemini.SupportedLang(lang) {
		writeError(w, http.StatusBadRequest, "lang must be en or hi")
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 45*time.Second)
	defer cancel()
	exp, source, err := s.ex.Explain(ctx, l, z, lang)
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

// simulate body: {"all": {...fixes}, "zones": {"Z14": {...fixes}}}
// "all" applies to every zone; entries in "zones" override it per zone.
func (s *Server) simulate(w http.ResponseWriter, r *http.Request) {
	l, ok := s.lake(w, r)
	if !ok {
		return
	}
	var req struct {
		All   *catchment.Fixes           `json:"all"`
		Zones map[string]catchment.Fixes `json:"zones"`
	}
	r.Body = http.MaxBytesReader(w, r.Body, 64<<10)
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON body")
		return
	}

	fixes := map[string]catchment.Fixes{}
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
	writeJSON(w, http.StatusOK, l.Simulate(fixes))
}
