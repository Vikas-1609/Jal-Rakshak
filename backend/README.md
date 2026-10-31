# JalRakshak backend

Go API for several Aravalli lake catchments: zone data, the intervention simulator, and Gemini explanations and chat.
Zone data is `data/zones.geojson` (the `04_multi_lake.js` export) and lake descriptions are `data/lakes.json`, both embedded in the binary.

## Layout

| Path | What it holds |
|---|---|
| `cmd/api` | `main`: reads config, loads the data, starts the server or runs `-pregen` |
| `data` | the embedded zone data (`data.FS`) |
| `internal/catchment` | lakes, zones, the fix simulator and summaries; no I/O beyond the embedded data |
| `internal/gemini` | explanations (`explain.go`), chat (`chat.go`), the facts Gemini sees (`facts.go`), model fallback (`models.go`) |
| `internal/api` | HTTP routes and handlers (`server.go`, `chat.go`), CORS and logging (`middleware.go`) |
| `internal/config` | `.env` loading and environment helpers |

Dependencies point one way: `api` → `gemini` → `catchment` → `data`.

## Run locally

Put the key in `backend/.env` (never committed, never copied into the Docker image):

```
GEMINI_API_KEY=<key from aistudio.google.com>
```

```powershell
go run ./cmd/api
go test ./...
```

Optional: `GEMINI_MODELS` (comma-separated, tried in order when one is out of quota or overloaded; default `gemini-3.1-flash-lite,gemini-3.5-flash,gemini-3-flash-preview`), `PORT` (default 8080), `ALLOWED_ORIGIN` (default `*`).

### With Docker

```powershell
docker build -t jalrakshak-api .
docker run --rm -p 8080:8080 --env-file .env jalrakshak-api
```

## Endpoints

| Method | Path | Returns |
|---|---|---|
| GET | `/api/lakes` | every lake with its totals |
| GET | `/api/lakes/{lake}/summary` | one lake's totals |
| GET | `/api/lakes/{lake}/zones` | zone GeoJSON for the map |
| GET | `/api/lakes/{lake}/zones/{id}` | one zone's fields plus `rank` |
| GET | `/api/lakes/{lake}/zones/{id}/explain?lang=en\|hi` | Gemini explanation; `source` is `gemini`, `cache` or `fallback` |
| POST | `/api/lakes/{lake}/zones/{id}/chat` | Gemini answer to a follow-up question |
| POST | `/api/lakes/{lake}/zones/{id}/chat/stream` | the same, streamed as Server-Sent Events |
| POST | `/api/lakes/{lake}/simulate` | tonnes before and after fixes, per zone and in total |

Chat body: the whole conversation, ending with the user's question.

```json
{"lang": "en", "messages": [{"role": "user", "text": "Which fix should we start with?"}]}
```

Simulate body: `all` applies to every zone, and `zones` overrides it per zone.

```json
{"all": {"bunds": true}, "zones": {"Z14": {"trenches": true, "reveg": true}}}
```

## Demo safety: save explanations in advance

```powershell
go run ./cmd/api -pregen      # writes data/explanations.json
```

Rebuild after this. If Gemini fails at demo time, the API serves these saved answers. Chat has no fallback.

## Deploy to Cloud Run

Cloud Run builds the `Dockerfile` with Cloud Build, so Docker isn't needed on your machine.
`.gcloudignore` keeps `.env` out of the upload. The Gemini key goes in Secret Manager.

One-time setup (replace `<project>`):

```powershell
gcloud config set project <project>
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com secretmanager.googleapis.com

# Store the Gemini key as a secret. Written without a trailing newline,
# which would otherwise become part of the key. The temp file is deleted after.
[IO.File]::WriteAllText("$env:TEMP\gemini.key", "<your Gemini key>")
gcloud secrets create gemini-api-key --data-file="$env:TEMP\gemini.key"
Remove-Item "$env:TEMP\gemini.key"

# Let Cloud Run's service account read it
$num = gcloud projects describe <project> --format="value(projectNumber)"
gcloud secrets add-iam-policy-binding gemini-api-key `
  --member="serviceAccount:$num-compute@developer.gserviceaccount.com" `
  --role="roles/secretmanager.secretAccessor"

# New projects: let the same account run source builds. Without this the first
# deploy fails with "does not have storage.objects.get access".
gcloud projects add-iam-policy-binding <project> `
  --member="serviceAccount:$num-compute@developer.gserviceaccount.com" `
  --role="roles/run.builder" --condition=None
```

Deploy (and redeploy after any change), from `backend/`:

```powershell
gcloud run deploy jalrakshak-api --source . --region asia-south1 --allow-unauthenticated `
  --set-env-vars "GOOGLE_GENAI_USE_VERTEXAI=true,GOOGLE_CLOUD_PROJECT=<project>,GOOGLE_CLOUD_LOCATION=global" `
  --memory 256Mi --max-instances 3
```

This uses **Vertex AI**: Gemini is billed to the project's Cloud billing account and the service
authenticates as its service account, so no API key is involved. Vertex needs, once:

```powershell
gcloud services enable aiplatform.googleapis.com
gcloud projects add-iam-policy-binding <project> `
  --member="serviceAccount:$num-compute@developer.gserviceaccount.com" `
  --role="roles/aiplatform.user" --condition=None
```

`GOOGLE_CLOUD_LOCATION=global`: the newer Gemini models aren't served from `asia-south1`.
To go back to the AI Studio key instead, deploy with `--set-secrets GEMINI_API_KEY=gemini-api-key:latest`
and `--remove-env-vars GOOGLE_GENAI_USE_VERTEXAI,GOOGLE_CLOUD_PROJECT,GOOGLE_CLOUD_LOCATION`.

The command prints the service URL. Build the app against it:

```powershell
flutter build web --dart-define-from-file=.env --dart-define=API_URL=https://<service-url>
```

`/healthz` works locally but not on Cloud Run, which reserves some paths ending in `z`; check the service with `/api/lakes` instead.

Optional hardening: `--set-env-vars ALLOWED_ORIGIN=https://<project>.web.app` limits which site can call the API from a browser (one origin; the default `*` allows any).
`--max-instances 3` caps how far Cloud Run scales, which also caps cost if the URL gets hammered.

## Updating the data

Rerun `04_multi_lake.js`, copy the export over `data/zones.geojson`, add any new lake to `data/lakes.json`, run `go test ./...`, and redeploy.
