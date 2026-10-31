package gemini

import (
	"testing"

	"jalrakshak/backend/internal/catchment"
)

func TestTonnesFormat(t *testing.T) {
	for in, want := range map[float64]string{
		0: "0", 999: "999", 1000: "1,000", 12003: "12,003",
		141386: "1,41,386", 1128950: "11,28,950", 12345678: "1,23,45,678",
	} {
		if got := tonnes(in); got != want {
			t.Errorf("tonnes(%.0f) = %q, want %q", in, got, want)
		}
	}
}

// Gemini is told to lead with the first fix, so it must be the biggest saving.
func TestFactsFixesSorted(t *testing.T) {
	r, err := catchment.LoadEmbedded()
	if err != nil {
		t.Fatal(err)
	}
	lake := r.ByID[catchment.DefaultLakeID]
	facts := zoneFacts(lake, lake.ByID["Z13"])
	fixes := facts["fixes"].([]map[string]any)
	if fixes[0]["fix"] != "contour trenches plus revegetation" {
		t.Errorf("Z13 first fix = %v, want trenches plus revegetation", fixes[0]["fix"])
	}
}
