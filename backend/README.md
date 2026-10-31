# JalRakshak backend

Go API for the Jaisamand catchment: zone data, the intervention simulator, and Gemini explanations.
Zone data is `data/zones.geojson`, a copy of the `03_scenarios.js` export, embedded in the binary.

## Run locally

```powershell
$env:GEMINI_API_KEY = "<key from aistudio.google.com>"
go run .
```

Optional: `GEMINI_MODEL` (default `gemini-3-flash-preview`), `PORT` (default 8080), `ALLOWED_ORIGIN` (default `*`).

## Endpoints

| Method | Path | Returns |
|---|---|---|
| GET | `/api/summary` | catchment totals, class and zone-type counts |
| GET | `/api/zones` | zone GeoJSON for the map |
| GET | `/api/zones/{id}` | one zone's fields plus `rank` |
| GET | `/api/zones/{id}/explain?lang=en\|hi` | Gemini explanation; `source` is `gemini`, `cache` or `fallback` |
| POST | `/api/simulate` | tonnes before and after fixes, per zone and in total |

Simulate body: `all` applies to every zone, and `zones` overrides it per zone.

```json
{"all": {"bunds": true}, "zones": {"Z14": {"trenches": true, "reveg": true}}}
```

## Demo safety: save explanations in advance

```powershell
go run . -pregen      # writes data/explanations.json (38 answers)
```

Rebuild after this. If Gemini fails at demo time, the API serves these saved answers.

## Deploy to Cloud Run

```powershell
gcloud run deploy jalrakshak-api --source . --region asia-south1 --allow-unauthenticated `
  --set-env-vars GEMINI_API_KEY=<key>
```

For anything beyond the hackathon, store the key in Secret Manager (`--set-secrets`) rather than as a plain env var.

## Updating the data

Rerun `03_scenarios.js`, then copy the new export over `data/zones.geojson` and run `go test ./...`.
