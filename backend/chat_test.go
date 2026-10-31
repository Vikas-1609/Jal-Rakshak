package main

import (
	"strings"
	"testing"
)

func TestCheckChat(t *testing.T) {
	user := ChatMessage{Role: "user", Text: "Where should we start?"}
	model := ChatMessage{Role: "model", Text: "Start with contour bunds."}
	many := make([]ChatMessage, maxChatTurns+1)
	for i := range many {
		many[i] = user
	}

	tests := []struct {
		name string
		msgs []ChatMessage
		ok   bool
	}{
		{"one question", []ChatMessage{user}, true},
		{"follow-up", []ChatMessage{user, model, user}, true},
		{"empty", nil, false},
		{"too many turns", many, false},
		{"ends with model", []ChatMessage{user, model}, false},
		{"bad role", []ChatMessage{{Role: "system", Text: "hi"}}, false},
		{"blank text", []ChatMessage{{Role: "user", Text: "  "}}, false},
		{"too long", []ChatMessage{{Role: "user", Text: strings.Repeat("a", maxChatMsgLen+1)}}, false},
		{"long reply ok", []ChatMessage{{Role: "model", Text: strings.Repeat("a", maxChatMsgLen+1)}, user}, true},
		// Hindi is counted in characters, not bytes.
		{"long hindi ok", []ChatMessage{{Role: "user", Text: strings.Repeat("क", maxChatMsgLen)}}, true},
	}
	for _, tt := range tests {
		if got := checkChat(tt.msgs) == ""; got != tt.ok {
			t.Errorf("%s: ok = %v, want %v (%q)", tt.name, got, tt.ok, checkChat(tt.msgs))
		}
	}
}
