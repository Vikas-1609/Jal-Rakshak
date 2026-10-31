package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestLogRequestsKeepsStatusAndFlush(t *testing.T) {
	var flushable bool
	h := logRequests(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Streaming chat needs Flush to reach the real writer.
		_, flushable = w.(http.Flusher)
		w.WriteHeader(http.StatusTeapot)
	}))
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest("GET", "/api/lakes", nil))

	if !flushable {
		t.Error("wrapped writer lost http.Flusher; streamed chat would arrive all at once")
	}
	if rec.Code != http.StatusTeapot {
		t.Errorf("status = %d, want %d", rec.Code, http.StatusTeapot)
	}
}
