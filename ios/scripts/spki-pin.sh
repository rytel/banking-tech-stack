#!/usr/bin/env bash
set -euo pipefail

# Computes an SPKI pin: base64(SHA-256(DER SubjectPublicKeyInfo)).
# The output matches what the app computes in SPKIHash.swift, so values
# printed here can be pasted straight into PinningConfiguration.swift.
#
# Usage:
#   spki-pin.sh --cert path/to/server.crt      pin from a certificate file (PEM)
#   spki-pin.sh --host api.example.com[:443]   pin from a live TLS endpoint
#   spki-pin.sh --key path/to/server.key       pin from a key file (PEM) — use this
#                                              to compute a backup pin before its
#                                              certificate even exists

usage() {
  grep '^#' "$0" | tail -n +2 | sed 's/^# \{0,1\}//'
  exit 1
}

hash_public_key() {
  # stdin: public key in PEM. stdout: the base64 SPKI pin.
  openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64
}

[[ $# -eq 2 ]] || usage

case "$1" in
  --cert)
    openssl x509 -in "$2" -pubkey -noout | hash_public_key
    ;;
  --host)
    host="${2%%:*}"
    port="${2##*:}"
    [[ "$port" == "$host" ]] && port=443
    openssl s_client -connect "$host:$port" -servername "$host" </dev/null 2>/dev/null \
      | openssl x509 -pubkey -noout | hash_public_key
    ;;
  --key)
    # Works for both private and public key files.
    if openssl pkey -in "$2" -pubout -outform pem >/dev/null 2>&1; then
      openssl pkey -in "$2" -pubout -outform pem | hash_public_key
    else
      openssl pkey -pubin -in "$2" -outform pem | hash_public_key
    fi
    ;;
  *)
    usage
    ;;
esac
