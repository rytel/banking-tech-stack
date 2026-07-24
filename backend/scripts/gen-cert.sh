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
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1" \
  -addext "extendedKeyUsage=serverAuth"

# Apple's TLS policy requires the serverAuth extended key usage (and a
# validity of at most 398 days) even for a locally anchored certificate —
# without it the iOS app rejects the connection before pinning is checked.

echo "Generated certs/server.crt and certs/server.key"

# The iOS app pins this certificate's public key (SPKI). Print the pin so it
# can be pasted into PinningConfiguration.swift after every regeneration.
pin=$(openssl x509 -in certs/server.crt -pubkey -noout \
  | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64)
echo "SPKI pin: $pin"
echo "Update the .local pin in ios/Projects/Core/Networking/Sources/Pinning/PinningConfiguration.swift"
