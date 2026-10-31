// Command api is the JalRakshak backend: it serves catchment zones for
// several Aravalli lakes, runs the intervention simulator, and asks Gemini
// to explain each zone and answer follow-up questions.
//
// Run with -pregen to generate every explanation into data/explanations.json,
// which is embedded as a fallback if Gemini is unreachable during the demo.
package main

import (
	"context"
	"flag"
	"log"
	"net/http"
	"strings"

	"jalrakshak/backend/data"
	"jalrakshak/backend/internal/api"
	"jalrakshak/backend/internal/catchment"
	"jalrakshak/backend/internal/config"
	"jalrakshak/backend/internal/gemini"
)

func main() {
	pregen := flag.Bool("pregen", false, "generate all explanations into data/explanations.json and exit")
	flag.Parse()

	if err := config.LoadDotEnv(".env"); err != nil {
		log.Fatalf("read .env: %v", err)
	}
	region, err := catchment.LoadEmbedded()
	if err != nil {
		log.Fatal(err)
	}
	ex, err := gemini.New(context.Background())
	if err != nil {
		log.Fatal(err)
	}

	if *pregen {
		if err := ex.Pregenerate(region, "data/"+data.ExplanationsFile); err != nil {
			log.Fatal(err)
		}
		return
	}

	addr := ":" + config.EnvOr("PORT", "8080")
	log.Printf("JalRakshak API on %s (%d lakes, models %s)", addr, len(region.Lakes), strings.Join(ex.Models(), " > "))
	log.Fatal(http.ListenAndServe(addr, api.New(region, ex).Handler()))
}
