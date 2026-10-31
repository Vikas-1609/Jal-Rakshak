package gemini

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"

	"google.golang.org/genai"

	"jalrakshak/backend/internal/catchment"
)

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
- Be short: under 120 words. Format with Markdown so it is easy to scan on a phone:
  - Start with a one-sentence direct answer.
  - Use "- " bullet lists for steps, options or reasons, with the key words in **bold**.
  - When the answer has distinct parts (for example what to do and how to get funding),
    give each a short "### " heading. Skip headings for a short answer.
  - No tables, code, links or images.
- Write only in the requested language. Only when answering in Hindi, use everyday rural words:
  मेड़बंदी (contour bunds), कंटूर खाई (contour trenches), पौधारोपण और घास लगाना (revegetation),
  गली प्लग (gully plugs), चेक डैम (check dams), मनरेगा (MGNREGA). Write numbers in digits as given.`

// ErrNoGemini means chat needs a live Gemini client; there is no fallback.
var ErrNoGemini = errors.New("gemini is not configured")

// saved returns an explanation already generated for the zone, if any.
func (e *Explainer) saved(lake *catchment.Lake, z *catchment.Zone, lang string) (Explanation, bool) {
	key := cacheKey(lake.ID, z.ID, lang)
	e.mu.RLock()
	ex, ok := e.cache[key]
	e.mu.RUnlock()
	if !ok {
		ex, ok = e.fallback[key]
	}
	return ex, ok
}

// Chat answers the last user message in history about one zone.
func (e *Explainer) Chat(ctx context.Context, lake *catchment.Lake, z *catchment.Zone, lang string, history []ChatMessage) (string, error) {
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

// ChatStream is Chat, passing the answer to onText piece by piece as
// Gemini writes it. An error from onText (client gone) stops the stream.
func (e *Explainer) ChatStream(ctx context.Context, lake *catchment.Lake, z *catchment.Zone, lang string, history []ChatMessage, onText func(string) error) error {
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
func (e *Explainer) chatRequest(lake *catchment.Lake, z *catchment.Zone, lang string, history []ChatMessage) ([]*genai.Content, *genai.GenerateContentConfig, error) {
	if e.client == nil {
		return nil, nil, ErrNoGemini
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
