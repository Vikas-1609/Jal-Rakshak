package gemini

import (
	"fmt"
	"sort"
	"strings"

	"jalrakshak/backend/internal/catchment"
)

// zoneFacts is what Gemini sees: numbers already rounded and formatted, and
// fix savings precomputed and sorted, so the model only explains, never calculates.
func zoneFacts(lake *catchment.Lake, z *catchment.Zone) map[string]any {
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
			"pct_of_zone_soil_loss_saved": fmt.Sprintf("%.0f%%", catchment.Pct(f.saved, z.TTotal)),
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
		"share_of_catchment_soil_loss_pct": fmt.Sprintf("%.1f%%", catchment.Pct(z.TTotal, catchT)),
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
