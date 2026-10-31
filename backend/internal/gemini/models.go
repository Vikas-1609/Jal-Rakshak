package gemini

import (
	"errors"
	"log"
	"net/http"
	"strings"

	"google.golang.org/genai"

	"jalrakshak/backend/internal/config"
)

// defaultModels are tried in order. Each has its own daily quota on the free
// tier, so a later one keeps the app working when an earlier one runs out.
// Flash-Lite first: 2–5 s per explanation against 20–40 s for 3.5 Flash,
// with the same numbers (they are precomputed; the model only words them).
const defaultModels = "gemini-3.1-flash-lite,gemini-3.5-flash,gemini-3-flash-preview"

// modelsFromEnv reads GEMINI_MODELS (comma-separated, first is preferred).
// GEMINI_MODEL, the older single-model setting, still works.
func modelsFromEnv() []string {
	list := config.EnvOr("GEMINI_MODELS", config.EnvOr("GEMINI_MODEL", defaultModels))
	var models []string
	for _, m := range strings.Split(list, ",") {
		if m = strings.TrimSpace(m); m != "" {
			models = append(models, m)
		}
	}
	return models
}

// geminiStatus is the HTTP status of a Gemini API error, or 0.
func geminiStatus(err error) int {
	var apiErr genai.APIError
	if errors.As(err, &apiErr) {
		return apiErr.Code
	}
	return 0
}

// tryNextModel reports whether another model might succeed where this one
// failed: out of quota (429), overloaded (503) or timed out on Google's side
// (504). Quotas are per model.
func tryNextModel(err error) bool {
	switch geminiStatus(err) {
	case http.StatusTooManyRequests, http.StatusServiceUnavailable, http.StatusGatewayTimeout:
		return true
	}
	return false
}

// setThinking sets how long model may think before answering.
func setThinking(cfg *genai.GenerateContentConfig, model string, level genai.ThinkingLevel) {
	cfg.ThinkingConfig = nil
	if strings.HasPrefix(model, "gemini-3") {
		cfg.ThinkingConfig = &genai.ThinkingConfig{ThinkingLevel: level}
	}
}

// withModels runs call with each model in turn until one succeeds or fails
// for a reason another model wouldn't fix.
func withModels[T any](e *Explainer, what string, call func(model string) (T, error)) (T, error) {
	var result T
	var err error
	for i, model := range e.models {
		result, err = call(model)
		if err == nil || !tryNextModel(err) || i == len(e.models)-1 {
			return result, err
		}
		log.Printf("%s: %s unavailable (%d), trying %s", what, model, geminiStatus(err), e.models[i+1])
	}
	return result, err
}
