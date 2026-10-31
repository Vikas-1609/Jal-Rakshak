package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"sort"
	"strings"
	"sync"

	"google.golang.org/genai"
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
func setThinking(config *genai.GenerateContentConfig, model string, level genai.ThinkingLevel) {
	config.ThinkingConfig = nil
	if strings.HasPrefix(model, "gemini-3") {
		config.ThinkingConfig = &genai.ThinkingConfig{ThinkingLevel: level}
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

// explain returns the explanation and where it came from: "cache", "gemini" or "fallback".
func (e *Explainer) explain(ctx context.Context, lake *Lake, z *Zone, lang string) (Explanation, string, error) {
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

func (e *Explainer) generate(ctx context.Context, lake *Lake, z *Zone, lang string) (Explanation, error) {
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

// ChatMessage is one turn of a follow-up conversation about a zone.
type ChatMessage struct {
	Role string `json:"role"` // "user" or "model"
	Text string `json:"text"`
}

const chatPrompt = `You answer follow-up questions for JalRakshak, a tool for gram panchayats,
watershed committees and farmers around lakes in the Aravalli hills of Rajasthan.
The user is looking at one zone of a lake's catchment. Its data and the explanation
they have already read are below. The numbers come from a soil-erosion model built on satellite data.

Rules:
- Ground answers in the zone data. Copy numbers exactly as written; never invent, recompute
  or estimate numbers (costs, yields, distances, dates, subsidy amounts).
- If the data cannot answer the question, say so plainly and suggest who can help: the gram
  panchayat, the block agriculture or watershed office, or the Krishi Vigyan Kendra.
- Stay on soil, water, farming, the lake and watershed works. Politely decline other topics.
- Answer the question actually asked first, then add context if it helps.
- On funding: contour bunds, contour trenches, revegetation, gully plugs and check dams can be
  done as MGNREGA watershed works, through the gram panchayat. Never quote amounts or rates.
- Plain words a farmer or panchayat member understands. No jargon like RUSLE, NDVI or "C factor".
- Be short: 2–5 sentences, or up to 4 lines starting with "- ". Plain text only, no headings,
  bold or tables.
- Write only in the requested language. Only when answering in Hindi, use everyday rural words:
  मेड़बंदी (contour bunds), कंटूर खाई (contour trenches), पौधारोपण और घास लगाना (revegetation),
  गली प्लग (gully plugs), चेक डैम (check dams), मनरेगा (MGNREGA). Write numbers in digits as given.`

// errNoGemini means chat needs a live Gemini client; there is no fallback.
var errNoGemini = errors.New("gemini is not configured")

// saved returns an explanation already generated for the zone, if any.
func (e *Explainer) saved(lake *Lake, z *Zone, lang string) (Explanation, bool) {
	key := cacheKey(lake.ID, z.ID, lang)
	e.mu.RLock()
	ex, ok := e.cache[key]
	e.mu.RUnlock()
	if !ok {
		ex, ok = e.fallback[key]
	}
	return ex, ok
}

// chat answers the last user message in history about one zone.
func (e *Explainer) chat(ctx context.Context, lake *Lake, z *Zone, lang string, history []ChatMessage) (string, error) {
	contents, config, err := e.chatRequest(lake, z, lang, history)
	if err != nil {
		return "", err
	}
	return withModels(e, "chat", func(model string) (string, error) {
		setThinking(config, model, genai.ThinkingLevelMinimal)
		res, err := e.client.Models.GenerateContent(ctx, model, contents, config)
		if err != nil {
			return "", fmt.Errorf("gemini %s: %w", model, err)
		}
		reply := strings.TrimSpace(res.Text())
		if reply == "" {
			return "", errors.New("gemini returned an empty reply")
		}
		return reply, nil
	})
}

// chatStream is chat, passing the answer to onText piece by piece as
// Gemini writes it. An error from onText (client gone) stops the stream.
func (e *Explainer) chatStream(ctx context.Context, lake *Lake, z *Zone, lang string, history []ChatMessage, onText func(string) error) error {
	contents, config, err := e.chatRequest(lake, z, lang, history)
	if err != nil {
		return err
	}
	// Quota and overload errors come before any text, so the next model can
	// still take over without the user seeing a half answer.
	_, err = withModels(e, "chat stream", func(model string) (struct{}, error) {
		setThinking(config, model, genai.ThinkingLevelMinimal)
		wrote := false
		for res, err := range e.client.Models.GenerateContentStream(ctx, model, contents, config) {
			if err != nil {
				if wrote {
					// Too late to switch models: part of the answer is out.
					return struct{}{}, fmt.Errorf("gemini %s stopped mid-answer: %v", model, err)
				}
				return struct{}{}, fmt.Errorf("gemini %s: %w", model, err)
			}
			if text := res.Text(); text != "" {
				wrote = true
				if err := onText(text); err != nil {
					return struct{}{}, err
				}
			}
		}
		if !wrote {
			return struct{}{}, errors.New("gemini returned an empty reply")
		}
		return struct{}{}, nil
	})
	return err
}

// chatRequest builds the Gemini request for a zone conversation.
func (e *Explainer) chatRequest(lake *Lake, z *Zone, lang string, history []ChatMessage) ([]*genai.Content, *genai.GenerateContentConfig, error) {
	if e.client == nil {
		return nil, nil, errNoGemini
	}
	facts, err := json.MarshalIndent(zoneFacts(lake, z), "", "  ")
	if err != nil {
		return nil, nil, err
	}
	system := fmt.Sprintf("%s\n\nAnswer in %s.\n\nZone data:\n%s", chatPrompt, langNames[lang], facts)
	if ex, ok := e.saved(lake, z, lang); ok {
		shown, _ := json.MarshalIndent(ex, "", "  ")
		system += "\n\nExplanation the user has already read:\n" + string(shown)
	}

	contents := make([]*genai.Content, 0, len(history))
	for _, m := range history {
		contents = append(contents, genai.NewContentFromText(m.Text, genai.Role(m.Role)))
	}
	// Thinking is set per model by the caller: minimal, so a chat answer
	// starts appearing quickly (the numbers are precomputed anyway).
	config := &genai.GenerateContentConfig{
		SystemInstruction: &genai.Content{Parts: []*genai.Part{{Text: system}}},
	}
	return contents, config, nil
}

// zoneFacts is what Gemini sees: numbers already rounded and formatted, and
// fix savings precomputed and sorted, so the model only explains, never calculates.
func zoneFacts(lake *Lake, z *Zone) map[string]any {
	c := lake.Catchment
	var catchT, catchLand float64
	rankByTonnes := 1
	for _, other := range c.Zones {
		catchT += other.TTotal
		catchLand += other.LandKm2
		if other.TTotal > z.TTotal {
			rankByTonnes++
		}
	}

	type fix struct {
		name, appliesTo string
		saved           float64
	}
	var fixes []fix
	if z.TCrop > 0 {
		fixes = append(fixes, fix{"contour bunds", "cropland", z.TCrop - z.TCropBunds})
	}
	if z.THill > 0 {
		fixes = append(fixes, fix{"contour trenches plus revegetation", "scrub, grass and bare hill land", z.THill - z.THillBoth})
	}
	sort.Slice(fixes, func(i, j int) bool { return fixes[i].saved > fixes[j].saved })
	fixList := []map[string]any{}
	for _, f := range fixes {
		fixList = append(fixList, map[string]any{
			"fix":                         f.name,
			"applies_to":                  f.appliesTo,
			"tonnes_saved_per_year":       tonnes(f.saved),
			"pct_of_zone_soil_loss_saved": fmt.Sprintf("%.0f%%", pct(f.saved, z.TTotal)),
		})
	}

	n := len(c.Zones)
	return map[string]any{
		"lake":                             lake.Name,
		"zone_id":                          z.ID,
		"zone_type":                        z.Type,
		"risk_class":                       z.RiskClass,
		"rank_by_soil_loss_per_hectare":    fmt.Sprintf("%d of %d", z.Rank, n),
		"rank_by_total_tonnes":             fmt.Sprintf("%d of %d", rankByTonnes, n),
		"soil_loss_t_per_ha_per_year":      fmt.Sprintf("%.1f", z.SoilLoss),
		"catchment_average_t_per_ha":       fmt.Sprintf("%.1f", catchT/(catchLand*100)),
		"zone_soil_loss_tonnes_per_year":   tonnes(z.TTotal),
		"share_of_catchment_soil_loss_pct": fmt.Sprintf("%.1f%%", pct(z.TTotal, catchT)),
		"land_area_km2":                    fmt.Sprintf("%.0f", z.LandKm2),
		"average_slope_deg":                fmt.Sprintf("%.1f", z.SlopeDeg),
		"annual_rainfall_mm":               fmt.Sprintf("%.0f", z.RainMM),
		"land_cover_pct": map[string]any{
			"cropland":         fmt.Sprintf("%.0f%%", z.CropFrac*100),
			"scrub_grass_bare": fmt.Sprintf("%.0f%%", z.HillFrac*100),
			"forest":           fmt.Sprintf("%.0f%%", z.TreeFrac*100),
			"built_up":         fmt.Sprintf("%.0f%%", z.BuiltFrac*100),
		},
		"cropland_bare_before_monsoon_pct": fmt.Sprintf("%.0f%%", z.CropBareFrac*100),
		"soil_loss_tonnes_by_land": map[string]any{
			"cropland":  tonnes(z.TCrop),
			"hill_land": tonnes(z.THill),
			"other":     tonnes(z.TOther),
		},
		"fixes": fixList,
	}
}

// tonnes formats a tonnage with Indian digit grouping: 141386 → "1,41,386".
func tonnes(v float64) string {
	s := fmt.Sprintf("%.0f", v)
	if len(s) <= 3 {
		return s
	}
	head, tail := s[:len(s)-3], s[len(s)-3:]
	var parts []string
	for len(head) > 2 {
		parts = append([]string{head[len(head)-2:]}, parts...)
		head = head[:len(head)-2]
	}
	parts = append([]string{head}, parts...)
	return strings.Join(parts, ",") + "," + tail
}
