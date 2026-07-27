---
description: Run the full verification loop for both sides — Go tests, then iOS build and tests
allowed-tools: Bash(go build:*), Bash(go test:*), Bash(go vet:*), Bash(gofmt:*), Bash(tuist generate:*), Bash(tuist build:*), Bash(tuist test:*), Read, Edit, Grep, Glob
---

Verify the whole repository. Run the cheap checks first and report everything at the end, but
stop early if a step fails in a way that makes later steps meaningless.

**Backend** (from `backend/`):

1. `gofmt -l .` — must print nothing.
2. `go vet ./...`
3. `go test ./...`

**iOS** (from `ios/`):

4. `tuist generate --no-open`
5. `tuist build`
6. `tuist test` — this runs the unit test targets. `AppUITests` needs a running backend, so if it
   is the only failure and nothing is listening on `https://localhost:8443`, report that rather
   than changing the test.

Never write build output into the repository (no `-derivedDataPath build`), and never hand-edit
generated `.xcodeproj` / `.xcworkspace` files.

Finish with a short summary: what passed, what failed, and the actual error for each failure.
