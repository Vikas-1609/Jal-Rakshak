package gemini

import (
	"errors"
	"fmt"
	"slices"
	"testing"

	"google.golang.org/genai"
)

func TestWithModelsFallsBack(t *testing.T) {
	e := &Explainer{models: []string{"a", "b", "c"}}
	quota := fmt.Errorf("gemini a: %w", genai.APIError{Code: 429})
	busy := fmt.Errorf("gemini b: %w", genai.APIError{Code: 503})
	bad := fmt.Errorf("gemini: %w", genai.APIError{Code: 400})

	tests := []struct {
		name     string
		fail     map[string]error
		wantUsed string
		wantTry  []string
		wantErr  bool
	}{
		{"first works", nil, "a", []string{"a"}, false},
		{"quota then busy then ok", map[string]error{"a": quota, "b": busy}, "c", []string{"a", "b", "c"}, false},
		{"bad request stops", map[string]error{"a": bad}, "", []string{"a"}, true},
		{"all out of quota", map[string]error{"a": quota, "b": quota, "c": quota}, "", []string{"a", "b", "c"}, true},
	}
	for _, tt := range tests {
		var tried []string
		used, err := withModels(e, tt.name, func(m string) (string, error) {
			tried = append(tried, m)
			if err := tt.fail[m]; err != nil {
				return "", err
			}
			return m, nil
		})
		if used != tt.wantUsed || (err != nil) != tt.wantErr || !slices.Equal(tried, tt.wantTry) {
			t.Errorf("%s: used %q err %v tried %v; want %q err=%v tried %v",
				tt.name, used, err, tried, tt.wantUsed, tt.wantErr, tt.wantTry)
		}
	}
}

func TestGeminiStatusUnwraps(t *testing.T) {
	err := fmt.Errorf("outer: %w", fmt.Errorf("gemini x: %w", genai.APIError{Code: 429}))
	if !tryNextModel(err) {
		t.Error("wrapped 429 should try the next model")
	}
	if tryNextModel(errors.New("network down")) {
		t.Error("non-API error should not try the next model")
	}
}

func TestGeminiModelsEnv(t *testing.T) {
	t.Setenv("GEMINI_MODELS", " x , y,,z ")
	if got := modelsFromEnv(); !slices.Equal(got, []string{"x", "y", "z"}) {
		t.Errorf("GEMINI_MODELS: got %v", got)
	}
	t.Setenv("GEMINI_MODELS", "")
	t.Setenv("GEMINI_MODEL", "only")
	if got := modelsFromEnv(); !slices.Equal(got, []string{"only"}) {
		t.Errorf("GEMINI_MODEL fallback: got %v", got)
	}
}
