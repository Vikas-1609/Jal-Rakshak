package main

import (
	"encoding/json"
	"fmt"
	"math"
	"sort"
)

// Zone holds the per-zone fields exported by 03_scenarios.js.
// Tonnes are per year; fractions are shares of the zone's land area.
type Zone struct {
	LakeID       string  `json:"lake_id"`
	LakeName     string  `json:"lake_name"`
	ID           string  `json:"zone_id"`
	Type         string  `json:"zone_type"` // hill, ravine, valley_farm, mixed
	RiskClass    string  `json:"risk_class"`
	RiskScore    float64 `json:"risk_score"` // 0–100 rank within the catchment
	SoilLoss     float64 `json:"soil_loss"`  // mean t/ha/yr
	SlopeDeg     float64 `json:"slope_deg"`
	NDVI         float64 `json:"ndvi"`
	BareFrac     float64 `json:"bare_frac"`
	RainMM       float64 `json:"rain_mm"`
	AreaKm2      float64 `json:"area_km2"`
	LandKm2      float64 `json:"land_km2"`
	CropFrac     float64 `json:"crop_frac"`
	HillFrac     float64 `json:"hill_frac"`
	TreeFrac     float64 `json:"tree_frac"`
	BuiltFrac    float64 `json:"built_frac"`
	CropBareFrac float64 `json:"crop_bare_frac"`

	TTotal      float64 `json:"t_total"`
	TCrop       float64 `json:"t_crop"`
	TCropBunds  float64 `json:"t_crop_bunds"`
	THill       float64 `json:"t_hill"`
	THillTrench float64 `json:"t_hill_trench"`
	THillReveg  float64 `json:"t_hill_reveg"`
	THillBoth   float64 `json:"t_hill_both"`
	TOther      float64 `json:"t_other"`

	Rank int `json:"rank"` // 1 = highest soil loss per hectare
}

// Catchment is the parsed zone data plus the raw GeoJSON served to the map.
type Catchment struct {
	Zones   []*Zone
	ByID    map[string]*Zone
	GeoJSON []byte
}

func loadCatchment(geojson []byte) (*Catchment, error) {
	var fc struct {
		Features []struct {
			Properties Zone `json:"properties"`
		} `json:"features"`
	}
	if err := json.Unmarshal(geojson, &fc); err != nil {
		return nil, fmt.Errorf("parse zones geojson: %w", err)
	}
	if len(fc.Features) == 0 {
		return nil, fmt.Errorf("zones geojson has no features")
	}

	c := &Catchment{ByID: map[string]*Zone{}, GeoJSON: geojson}
	for i := range fc.Features {
		z := fc.Features[i].Properties
		c.Zones = append(c.Zones, &z)
		c.ByID[z.ID] = &z
	}
	sort.Slice(c.Zones, func(i, j int) bool { return c.Zones[i].SoilLoss > c.Zones[j].SoilLoss })
	for i, z := range c.Zones {
		z.Rank = i + 1
	}
	return c, nil
}

// Fixes are the interventions toggled for one zone.
// Bunds apply to cropland; trenches and revegetation apply to hill land.
type Fixes struct {
	Bunds    bool `json:"bunds"`
	Trenches bool `json:"trenches"`
	Reveg    bool `json:"reveg"`
}

// tonnes returns the zone's soil loss (t/yr) with the given fixes applied.
// Each fix only changes its own land type, so the parts simply add up.
func (z *Zone) tonnes(f Fixes) float64 {
	crop := z.TCrop
	if f.Bunds {
		crop = z.TCropBunds
	}
	hill := z.THill
	switch {
	case f.Trenches && f.Reveg:
		hill = z.THillBoth
	case f.Trenches:
		hill = z.THillTrench
	case f.Reveg:
		hill = z.THillReveg
	}
	return crop + hill + z.TOther
}

type ZoneResult struct {
	ID          string  `json:"zone_id"`
	BaselineT   float64 `json:"baseline_t"`
	ScenarioT   float64 `json:"scenario_t"`
	SavedT      float64 `json:"saved_t"`
	SavedPct    float64 `json:"saved_pct"`
	SoilLossNew float64 `json:"soil_loss_new"` // t/ha/yr after fixes
}

type SimResult struct {
	BaselineT float64      `json:"baseline_t"`
	ScenarioT float64      `json:"scenario_t"`
	SavedT    float64      `json:"saved_t"`
	SavedPct  float64      `json:"saved_pct"`
	Zones     []ZoneResult `json:"zones"`
}

// simulate applies fixes per zone ID. Zones not in the map stay at baseline.
func (c *Catchment) simulate(fixes map[string]Fixes) SimResult {
	var r SimResult
	for _, z := range c.Zones {
		scen := z.tonnes(fixes[z.ID])
		r.BaselineT += z.TTotal
		r.ScenarioT += scen
		r.Zones = append(r.Zones, ZoneResult{
			ID:          z.ID,
			BaselineT:   round(z.TTotal, 0),
			ScenarioT:   round(scen, 0),
			SavedT:      round(z.TTotal-scen, 0),
			SavedPct:    round(pct(z.TTotal-scen, z.TTotal), 1),
			SoilLossNew: round(scen/(z.LandKm2*100), 2),
		})
	}
	r.SavedT = round(r.BaselineT-r.ScenarioT, 0)
	r.SavedPct = round(pct(r.BaselineT-r.ScenarioT, r.BaselineT), 1)
	r.BaselineT = round(r.BaselineT, 0)
	r.ScenarioT = round(r.ScenarioT, 0)
	return r
}

type Summary struct {
	Zones          int            `json:"zones"`
	LandKm2        float64        `json:"land_km2"`
	TotalT         float64        `json:"total_t"`
	MeanSoilLoss   float64        `json:"mean_soil_loss"` // t/ha/yr
	CropT          float64        `json:"crop_t"`
	HillT          float64        `json:"hill_t"`
	OtherT         float64        `json:"other_t"`
	AllFixesT      float64        `json:"all_fixes_t"`
	AllFixesPct    float64        `json:"all_fixes_saved_pct"`
	ClassCounts    map[string]int `json:"class_counts"`
	ZoneTypeCounts map[string]int `json:"zone_type_counts"`
}

func (c *Catchment) summary() Summary {
	s := Summary{Zones: len(c.Zones), ClassCounts: map[string]int{}, ZoneTypeCounts: map[string]int{}}
	all := Fixes{Bunds: true, Trenches: true, Reveg: true}
	for _, z := range c.Zones {
		s.LandKm2 += z.LandKm2
		s.TotalT += z.TTotal
		s.CropT += z.TCrop
		s.HillT += z.THill
		s.OtherT += z.TOther
		s.AllFixesT += z.tonnes(all)
		s.ClassCounts[z.RiskClass]++
		s.ZoneTypeCounts[z.Type]++
	}
	s.MeanSoilLoss = round(s.TotalT/(s.LandKm2*100), 2)
	s.AllFixesPct = round(pct(s.TotalT-s.AllFixesT, s.TotalT), 1)
	s.LandKm2 = round(s.LandKm2, 0)
	s.TotalT = round(s.TotalT, 0)
	s.CropT = round(s.CropT, 0)
	s.HillT = round(s.HillT, 0)
	s.OtherT = round(s.OtherT, 0)
	s.AllFixesT = round(s.AllFixesT, 0)
	return s
}

func pct(part, whole float64) float64 {
	if whole == 0 {
		return 0
	}
	return part / whole * 100
}

func round(v float64, places int) float64 {
	p := math.Pow(10, float64(places))
	return math.Round(v*p) / p
}
