#!/usr/bin/env bash
set -euo pipefail

# Generates a self-signed TLS certificate for local development.
# Needed so the iOS client can exercise certificate pinning later.

cd "$(dirname "$0")/.."
mkdir -p certs

openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
  -keyout certs/server.key -out certs/server.crt \
  -days 365 -nodes \
  -subj "/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

echo "Generated certs/server.crt and certs/server.key"
