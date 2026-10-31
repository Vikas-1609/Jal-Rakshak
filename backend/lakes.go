package main

import (
	"encoding/json"
	"fmt"
	"log"
)

// LakeMeta is the hand-written description of a lake (data/lakes.json).
type LakeMeta struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	District string `json:"district"`
	Story    string `json:"story"` // one line on why this catchment matters

	// Hindi versions for the app's हिंदी mode.
	NameHi     string `json:"name_hi,omitempty"`
	DistrictHi string `json:"district_hi,omitempty"`
	StoryHi    string `json:"story_hi,omitempty"`
}

// Lake is one lake's catchment: its metadata plus its zones.
type Lake struct {
	LakeMeta
	*Catchment
}

// Region holds every lake that has zone data, in lakes.json order.
type Region struct {
	Lakes []*Lake
	ByID  map[string]*Lake
}

// defaultLakeID is used for zones exported before multi-lake support (no lake_id).
const defaultLakeID = "jaisamand"

// loadRegion splits the combined zone GeoJSON by lake_id and builds one
// Catchment per lake. Lakes listed in lakes.json without data are skipped.
func loadRegion(geojson, lakesJSON []byte) (*Region, error) {
	var metas []LakeMeta
	if err := json.Unmarshal(lakesJSON, &metas); err != nil {
		return nil, fmt.Errorf("parse lakes.json: %w", err)
	}
	var fc struct {
		Features []json.RawMessage `json:"features"`
	}
	if err := json.Unmarshal(geojson, &fc); err != nil {
		return nil, fmt.Errorf("parse zones geojson: %w", err)
	}

	byLake := map[string][]json.RawMessage{}
	for _, raw := range fc.Features {
		var f struct {
			Properties struct {
				LakeID string `json:"lake_id"`
			} `json:"properties"`
		}
		if err := json.Unmarshal(raw, &f); err != nil {
			return nil, fmt.Errorf("parse feature: %w", err)
		}
		id := f.Properties.LakeID
		if id == "" {
			id = defaultLakeID
		}
		byLake[id] = append(byLake[id], raw)
	}

	r := &Region{ByID: map[string]*Lake{}}
	for _, meta := range metas {
		features, ok := byLake[meta.ID]
		if !ok {
			log.Printf("lake %s: no zone data yet, skipped", meta.ID)
			continue
		}
		delete(byLake, meta.ID)
		lakeGeoJSON, err := json.Marshal(map[string]any{"type": "FeatureCollection", "features": features})
		if err != nil {
			return nil, err
		}
		c, err := loadCatchment(lakeGeoJSON)
		if err != nil {
			return nil, fmt.Errorf("lake %s: %w", meta.ID, err)
		}
		for _, z := range c.Zones {
			z.LakeID, z.LakeName = meta.ID, meta.Name
		}
		lake := &Lake{LakeMeta: meta, Catchment: c}
		r.Lakes = append(r.Lakes, lake)
		r.ByID[meta.ID] = lake
	}
	for id := range byLake {
		log.Printf("lake %s: has zone data but no entry in lakes.json, skipped", id)
	}
	if len(r.Lakes) == 0 {
		return nil, fmt.Errorf("no lakes with zone data")
	}
	return r, nil
}

// LakeSummary is one row of /api/lakes.
type LakeSummary struct {
	LakeMeta
	Summary
	TopZone string `json:"top_zone"` // zone losing the most tonnes per year
}

func (l *Lake) summaryRow() LakeSummary {
	top := l.Zones[0]
	for _, z := range l.Zones {
		if z.TTotal > top.TTotal {
			top = z
		}
	}
	return LakeSummary{LakeMeta: l.LakeMeta, Summary: l.summary(), TopZone: top.ID}
}
