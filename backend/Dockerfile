# JalRakshak API. Zone data (data/) is embedded in the binary at build time.
# Secrets are never baked in: GEMINI_API_KEY comes from the environment
# (on Cloud Run, from Secret Manager).

FROM golang:1.25-alpine AS build
WORKDIR /src
# Dependencies first, so code changes don't re-download them.
COPY go.mod go.sum ./
RUN go mod download
COPY . .
# Static binary: no C libraries needed in the runtime image.
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /jalrakshak ./cmd/api

# Distroless: just the binary, CA certificates (for HTTPS to Gemini) and a
# non-root user. No shell or package manager to attack.
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /jalrakshak /jalrakshak
# Cloud Run sets PORT; 8080 is the local default.
ENV PORT=8080
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/jalrakshak"]
