// Package gemini turns a zone's model results into plain-language advice:
// a structured explanation per zone and language, and follow-up chat.
// It falls back across Gemini models when one is out of quota, and to saved
// explanations when Gemini is unreachable.
package gemini

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"sync"
	"time"

	"google.golang.org/genai"

	"jalrakshak/backend/data"
	"jalrakshak/backend/internal/catchment"
)

// Explanation is the structured answer Gemini returns for one zone.
type Explanation struct {
	Headline  string   `json:"headline"`
	Why       []string `json:"why"`
	Actions   []Action `json:"actions"`
	FarmerTip string   `json:"farmer_tip"`
}

type Action struct {
	Title  string `json:"title"`
	Where  string `json:"where"`
	Impact string `json:"impact"`
}

// langNames are the supported answer languages, as told to Gemini.
var langNames = map[string]string{
	"en": "English",
	"hi": "Hindi, in Devanagari script",
}

const systemPrompt = `You explain soil-erosion results for JalRakshak, a tool for gram panchayats,
watershed committees and farmers around lakes in the Aravalli hills of southern Rajasthan.

You receive data for one zone of a lake's catchment as JSON; "lake" names the lake it drains into. The numbers come from a RUSLE soil-erosion model
built on satellite data. Write a short explanation and recommendations.

Rules:
- Use only the numbers given, copied exactly as written (they are already formatted).
  Never invent, recompute or reformat numbers. Never add numbers that are not in the data
  (costs, yields, distances, dates).
- Plain words a farmer or panchayat member understands. No jargon like RUSLE, NDVI or "C factor".
  Say "plant cover" instead of NDVI.
- "headline": one sentence, under 20 words, built on the most striking fact: the zone's rank
  or its share of the catchment's soil loss.
- "why": 2–3 short points, each tied to a number from the data.
- "actions": 2–3 fixes.
  1. Include every fix in "fixes", in the same order (it is sorted by tonnes saved, largest first).
  2. "impact" must quote the tonnes saved or percentage for that fix from the data.
  3. You may add one structural work matched to zone_type, after the fixes from the list,
     describing its benefit without numbers:
       hill        → gully plugs on drainage lines
       ravine      → gully plugs and small check dams across side channels
       valley_farm → grass strips on field edges
       mixed       → gully plugs on drainage lines
  For ravine zones, say the real soil loss is likely higher, because the model does not count gully erosion.
  You may say these works can be funded under MGNREGA watershed works.
- "farmer_tip": one practical tip for farmers in this zone. If cropland_bare_before_monsoon_pct is 30
  or more, advise not to spread fertilizer right before heavy rain is forecast, since it washes off bare fields.
- Keep every string short: one or two sentences.
- In Hindi, use everyday rural words: मेड़बंदी (contour bunds), कंटूर खाई (contour trenches),
  पौधारोपण और घास लगाना (revegetation), गली प्लग (gully plugs), चेक डैम (check dams),
  मनरेगा (MGNREGA), मौसम का पूर्वानुमान (weather forecast). Write numbers in digits as given.`

var explanationSchema = &genai.Schema{
	Type: genai.TypeObject,
	Properties: map[string]*genai.Schema{
		"headline": {Type: genai.TypeString, Description: "One-sentence summary of the zone's risk"},
		"why": {
			Type:        genai.TypeArray,
			Description: "2–3 reasons the zone loses soil, each tied to a number",
			Items:       &genai.Schema{Type: genai.TypeString},
		},
		"actions": {
			Type:        genai.TypeArray,
			Description: "2–3 recommended fixes, most effective first",
			Items: &genai.Schema{
				Type: genai.TypeObject,
				Properties: map[string]*genai.Schema{
					"title":  {Type: genai.TypeString, Description: "Name of the fix"},
					"where":  {Type: genai.TypeString, Description: "Which land in the zone it applies to"},
					"impact": {Type: genai.TypeString, Description: "Expected effect, quoting the data"},
				},
				Required:         []string{"title", "where", "impact"},
				PropertyOrdering: []string{"title", "where", "impact"},
			},
		},
		"farmer_tip": {Type: genai.TypeString, Description: "One practical tip for farmers"},
	},
	Required:         []string{"headline", "why", "actions", "farmer_tip"},
	PropertyOrdering: []string{"headline", "why", "actions", "farmer_tip"},
}

// Explainer calls Gemini and caches answers per lake, zone and language.
// If Gemini is unavailable it serves pre-generated answers (data/explanations.json).
type Explainer struct {
	client *genai.Client // nil when no API key is configured
	// Tried in order: when one is out of quota or overloaded, the next
	// gets the same request.
	models   []string
	fallback map[string]Explanation

	mu    sync.RWMutex
	cache map[string]Explanation
}

func cacheKey(lakeID, zoneID, lang string) string { return lakeID + "|" + zoneID + "|" + lang }

// Explain returns the explanation and where it came from: "cache", "gemini" or "fallback".
func (e *Explainer) Explain(ctx context.Context, lake *catchment.Lake, z *catchment.Zone, lang string) (Explanation, string, error) {
	key := cacheKey(lake.ID, z.ID, lang)
	e.mu.RLock()
	ex, ok := e.cache[key]
	e.mu.RUnlock()
	if ok {
		return ex, "cache", nil
	}

	if e.client != nil {
		ex, err := e.generate(ctx, lake, z, lang)
		if err == nil {
			e.mu.Lock()
			e.cache[key] = ex
			e.mu.Unlock()
			return ex, "gemini", nil
		}
		if fb, ok := e.fallback[key]; ok {
			return fb, "fallback", nil
		}
		return Explanation{}, "", err
	}

	if fb, ok := e.fallback[key]; ok {
		return fb, "fallback", nil
	}
	return Explanation{}, "", fmt.Errorf("no Gemini client and no saved explanation for %s", key)
}

func (e *Explainer) generate(ctx context.Context, lake *catchment.Lake, z *catchment.Zone, lang string) (Explanation, error) {
	facts, err := json.MarshalIndent(zoneFacts(lake, z), "", "  ")
	if err != nil {
		return Explanation{}, err
	}
	prompt := fmt.Sprintf("Write the answer in %s.\n\nZone data:\n%s", langNames[lang], facts)

	config := &genai.GenerateContentConfig{
		SystemInstruction: &genai.Content{Parts: []*genai.Part{{Text: systemPrompt}}},
		ResponseMIMEType:  "application/json",
		ResponseSchema:    explanationSchema,
	}

	return withModels(e, "explain", func(model string) (Explanation, error) {
		setThinking(config, model, genai.ThinkingLevelMinimal)
		res, err := e.client.Models.GenerateContent(ctx, model, genai.Text(prompt), config)
		if err != nil {
			return Explanation{}, fmt.Errorf("gemini %s: %w", model, err)
		}
		var ex Explanation
		if err := json.Unmarshal([]byte(res.Text()), &ex); err != nil {
			return Explanation{}, fmt.Errorf("gemini %s returned invalid JSON: %w", model, err)
		}
		return ex, nil
	})
}

// SupportedLang reports whether answers can be written in lang ("en", "hi").
func SupportedLang(lang string) bool {
	_, ok := langNames[lang]
	return ok
}

// New sets up the explainer: models from the environment, saved explanations
// from the embedded data, and a Gemini client if one can be configured.
// The client reads GEMINI_API_KEY, or uses Vertex AI if GOOGLE_GENAI_USE_VERTEXAI=true.
// Without a client, only saved explanations are served and chat is off.
func New(ctx context.Context) (*Explainer, error) {
	e := &Explainer{
		models:   modelsFromEnv(),
		fallback: map[string]Explanation{},
		cache:    map[string]Explanation{},
	}
	if b, err := data.FS.ReadFile(data.ExplanationsFile); err == nil {
		if err := json.Unmarshal(b, &e.fallback); err != nil {
			return nil, fmt.Errorf("parse %s: %w", data.ExplanationsFile, err)
		}
	}
	if client, err := genai.NewClient(ctx, nil); err != nil {
		log.Printf("Gemini disabled (%v); serving %d saved explanations only", err, len(e.fallback))
	} else {
		e.client = client
	}
	return e, nil
}

// Enabled reports whether a live Gemini client is configured.
func (e *Explainer) Enabled() bool { return e.client != nil }

// Models lists the Gemini models in the order they are tried.
func (e *Explainer) Models() []string { return e.models }

// Pregenerate asks Gemini for every zone's explanation in every language and
// writes them to path, to embed as the fallback for when Gemini is down.
func (e *Explainer) Pregenerate(region *catchment.Region, path string) error {
	if e.client == nil {
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
					exp, err = e.generate(ctx, l, z, lang)
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
	if err := os.WriteFile(path, b, 0o644); err != nil {
		return err
	}
	log.Printf("wrote %d explanations to %s; rebuild to embed them", len(out), path)
	return nil
}
