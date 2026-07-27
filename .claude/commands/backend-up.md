---
description: Start the Go backend on https://localhost:8443, generating the cert if missing
allowed-tools: Bash(ls:*), Bash(./scripts/gen-cert.sh:*), Bash(go run:*), Bash(curl -k https://localhost:8443/:*), Read, Edit
---

Start the backend so the iOS app (or the UI tests) can talk to it.

1. From `backend/`, check whether `certs/server.crt` and `certs/server.key` exist.
2. If either is missing, run `./scripts/gen-cert.sh`. **The script prints a new SPKI pin — the
   iOS app pins it.** If you generated a new certificate, paste that pin into the `.local` pin
   set in `ios/Projects/Core/Networking/Sources/Pinning/PinningConfiguration.swift`, otherwise
   every request from the app fails with `NetworkError.pinningFailure`.
3. Start the server in the background: `go run ./cmd/server` from `backend/`.
   It must run from `backend/` — the certificate paths in `main.go` are relative.
4. Confirm it is up with `curl -k https://localhost:8443/health` (expect HTTP 200).

Tell the user the server is running, on which URL, and remind them the demo credentials are
`demo` / `demo1234`.
