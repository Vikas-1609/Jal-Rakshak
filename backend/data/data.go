// Package data embeds the zone data into the binary, so the server needs no
// files at runtime.
//
//	zones.geojson      every lake's zones, exported from Earth Engine (04_multi_lake.js)
//	lakes.json         hand-written lake names and descriptions
//	explanations.json  optional: Gemini explanations saved by `api -pregen`
package data

import "embed"

//go:embed *.json *.geojson
var FS embed.FS

// ExplanationsFile is where -pregen writes, relative to backend/, and its
// name inside FS once rebuilt.
const ExplanationsFile = "explanations.json"
