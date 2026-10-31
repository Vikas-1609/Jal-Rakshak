package main

import (
	"math"
	"testing"
)

// testCatchment returns Jaisamand, the lake the tests' expectations are based on.
func testCatchment(t *testing.T) *Catchment {
	t.Helper()
	r, err := loadEmbeddedRegion()
	if err != nil {
		t.Fatal(err)
	}
	return r.ByID[defaultLakeID].Catchment
}

func TestZonesLoad(t *testing.T) {
	c := testCatchment(t)
	if len(c.Zones) != 19 {
		t.Fatalf("got %d zones, want 19", len(c.Zones))
	}
	if c.Zones[0].Rank != 1 || c.Zones[0].SoilLoss < c.Zones[1].SoilLoss {
		t.Errorf("zones not ranked by soil loss")
	}
}

// The export splits each zone's tonnes into cropland, hill land and other;
// the simulator relies on those parts adding back up to the total.
func TestPartsSumToTotal(t *testing.T) {
	for _, z := range testCatchment(t).Zones {
		if d := math.Abs(z.TCrop + z.THill + z.TOther - z.TTotal); d > 1 {
			t.Errorf("%s: parts differ from total by %.1f t", z.ID, d)
		}
	}
}

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
	c := testCatchment(t)
	lake := &Lake{LakeMeta: LakeMeta{ID: "jaisamand", Name: "Jaisamand Lake"}, Catchment: c}
	facts := zoneFacts(lake, c.ByID["Z13"])
	fixes := facts["fixes"].([]map[string]any)
	if fixes[0]["fix"] != "contour trenches plus revegetation" {
		t.Errorf("Z13 first fix = %v, want trenches plus revegetation", fixes[0]["fix"])
	}
}

// The embedded data loads into lakes; zones without lake_id go to Jaisamand.
func TestLoadRegion(t *testing.T) {
	r, err := loadEmbeddedRegion()
	if err != nil {
		t.Fatal(err)
	}
	jai, ok := r.ByID[defaultLakeID]
	if !ok {
		t.Fatalf("no %s lake in region", defaultLakeID)
	}
	if len(jai.Zones) != 19 || jai.Zones[0].LakeID != defaultLakeID {
		t.Errorf("jaisamand: %d zones, lake_id %q", len(jai.Zones), jai.Zones[0].LakeID)
	}
	for _, l := range r.Lakes {
		total := 0
		for _, z := range l.Zones {
			if z.LakeID != l.ID {
				t.Errorf("zone %s has lake_id %q, in lake %s", z.ID, z.LakeID, l.ID)
			}
			total++
		}
		if total == 0 {
			t.Errorf("lake %s has no zones", l.ID)
		}
	}
}

func TestSimulate(t *testing.T) {
	c := testCatchment(t)

	none := c.simulate(nil)
	if none.SavedT != 0 {
		t.Errorf("no fixes saved %.0f t, want 0", none.SavedT)
	}

	all := map[string]Fixes{}
	for _, z := range c.Zones {
		all[z.ID] = Fixes{Bunds: true, Trenches: true, Reveg: true}
	}
	r := c.simulate(all)
	if r.ScenarioT >= r.BaselineT {
		t.Errorf("all fixes did not reduce soil loss: %.0f >= %.0f", r.ScenarioT, r.BaselineT)
	}
	if s := c.summary(); math.Abs(s.AllFixesT-r.ScenarioT) > 1 {
		t.Errorf("summary all-fixes %.0f != simulate %.0f", s.AllFixesT, r.ScenarioT)
	}

	// Each fix alone must save something but less than all fixes together.
	for name, f := range map[string]Fixes{"bunds": {Bunds: true}, "trenches": {Trenches: true}, "reveg": {Reveg: true}} {
		one := map[string]Fixes{}
		for _, z := range c.Zones {
			one[z.ID] = f
		}
		got := c.simulate(one).SavedT
		if got <= 0 || got >= r.SavedT {
			t.Errorf("%s saved %.0f t, want between 0 and %.0f", name, got, r.SavedT)
		}
	}
}
