---
description: Start the backend, run the end-to-end iOS UI tests, then stop the backend
allowed-tools: Bash(ls:*), Bash(./scripts/gen-cert.sh:*), Bash(go run:*), Bash(curl -k https://localhost:8443/:*), Bash(lsof:*), Bash(kill:*), Bash(tuist generate:*), Bash(tuist test:*), Read
---

Run a real end-to-end check: `AppUITests` needs a live backend, unlike the mock-only unit tests.

1. From `backend/`, check whether `certs/server.crt` and `certs/server.key` exist; if not, run
   `./scripts/gen-cert.sh`. If it prints a new SPKI pin, stop and tell the user to run
   `/rotate-pin` first — a mismatched pin makes every request fail with
   `NetworkError.pinningFailure`, and the UI tests would fail for the wrong reason.
2. Start the server in the background from `backend/`: `go run ./cmd/server`.
3. Confirm it's up: `curl -k https://localhost:8443/health` (expect HTTP 200).
4. From `ios/`, run `tuist generate --no-open`, then `tuist test AppUITests`.
5. Stop the backend process you started in step 2, regardless of whether the tests passed.
6. Report pass/fail with the actual failure output if any, and confirm the backend was shut down.

Don't leave a backend process running after this command finishes.
