# CLAUDE.md — backend

Guidance for Claude Code when working in `backend/`. For the iOS app see [../ios/CLAUDE.md](../ios/CLAUDE.md).

## Commands

Run everything from the `backend/` directory — the server loads its certificate from the
relative path `certs/server.crt`, so it fails to start from anywhere else.

```bash
./scripts/gen-cert.sh   # generate the self-signed cert (needed once, before the first run)
go run ./cmd/server     # serves HTTPS on https://localhost:8443
go test ./...           # run all tests (fast, no network, no cert needed)
go test ./internal/auth # run one package's tests
go vet ./...            # static checks
gofmt -l .              # list unformatted files; use gofmt -w to fix
```

## What this service is for

This backend exists only to give the iOS app something real to talk to. It is a "breadth check",
not a project in its own right. Keep it small: standard library `net/http` plus the one
dependency `github.com/coder/websocket`. **Do not add frameworks, routers, databases, or ORMs.**
If a task can be solved with the standard library, solve it that way.

## Package layout and the one hard rule

`internal/models` is the shared bottom layer: it holds data structures only and **must not import
`handlers`, `auth`, `topics`, or `ticker`**. Every other package may import `models`. This keeps
the dependency graph acyclic without any tooling to enforce it.

| Package | Purpose |
|---|---|
| `cmd/server` | `main` — builds the services, starts TLS listener on `:8443` |
| `internal/handlers` | Routing and HTTP glue. **No business logic here.** |
| `internal/auth` | Login, JWT issuing/verifying, refresh store, bearer middleware |
| `internal/topics` | Static topic list and search |
| `internal/ticker` | Builds the messages pushed over the WebSocket |
| `internal/models` | Shared structs (`Topic`, `TokenPair`, `LoginRequest`, …) |

Handlers are written as constructor functions returning `http.HandlerFunc`
(`loginHandler(authSvc)`), so dependencies are injected instead of being package globals. Follow
that shape when adding a route, and register it in `handlers.NewRouter`.

## Endpoints

| Endpoint | Auth | Notes |
|---|---|---|
| `GET /health` | no | Returns 200, empty body |
| `POST /auth/login` | no | `{username, password}` → access + refresh token |
| `POST /auth/refresh` | no | `{refresh_token}` → new access **and new refresh** token |
| `GET /topics` | no | Optional `?q=` filters by title, case-insensitive |
| `GET /topics/{id}` | no | 404 as `{"error": "..."}` when unknown |
| `GET /ws/ticker` | no | WebSocket, one message per second |
| `GET /secret` | **yes** | The only route behind `auth.Service.Middleware` |

All JSON field names are **snake_case on purpose** (`access_token`, `expires_in`). The iOS side
uses this to practise decoding strategies — do not "fix" it to camelCase.

Errors are always the JSON body `{"error": "message"}` via `writeError`. The one exception is
the middleware, which writes that shape by hand because it runs before the handler layer.

## Auth model

- **ES256 (asymmetric), not HS256.** The signing key is generated at startup by
  `generateSigningKey()` and lives **only in memory**. Restarting the server invalidates every
  issued token — that is expected, not a bug to fix. A real system would load the key from a
  secret store.
- **The JWT code is hand-rolled** (`internal/auth/jwt.go`), no third-party library. Note
  `encodeSignature`: JWS wants the fixed 64-byte `r||s` layout, *not* the ASN.1 DER that
  `ecdsa.SignASN1` produces. Keep it that way; do not swap in a JWT library.
- Access token TTL is 5 minutes, refresh token TTL is 24 hours (`accessTokenTTL`,
  `refreshTokenTTL`). The short access TTL is deliberate: it makes the iOS
  `TokenRefreshCoordinator` single-flight path easy to exercise by hand.
- **Refresh tokens are single-use and rotated.** `refreshStore.consume` deletes the token before
  returning, so every refresh hands back a new one and the client must store it.
- The only valid credentials are the hardcoded `demo` / `demo1234`, compared with
  `subtle.ConstantTimeCompare`. There is no user store and none is needed.
- Refresh tokens are kept in an in-memory map guarded by a mutex, and are lost on restart.

## TLS and the pin the iOS app depends on

`scripts/gen-cert.sh` writes `backend/certs/server.{crt,key}` and prints the certificate's SPKI
hash. **Every regeneration changes that hash.** The iOS app pins it, so after regenerating you
must paste the new pin into
`ios/Projects/Core/Networking/Sources/Pinning/PinningConfiguration.swift` (the `.local` pin set),
or the app fails every request with `NetworkError.pinningFailure`. The script prints this
reminder itself.

The cert carries `serverAuth` extended key usage on purpose — Apple's TLS policy rejects the
connection without it, before pinning is even evaluated. Certs and keys are gitignored.

## Ticker WebSocket

`tickerHandler` upgrades the connection and pushes one message per second. The loop is driven by
`r.Context()`, which `net/http` cancels as soon as the client disconnects — so no extra goroutine
is needed to watch for disconnects, and the loop can never outlive the request. Each write has
its own 5-second timeout. Keep this shape when touching the ticker.

## Testing

Tests use only `testing` and `net/http/httptest` — no test framework, no mocking library.
`routes_test.go` exercises the router end to end through `httptest.NewServer`, which is the
preferred style for anything route-shaped. Tests never need TLS or a generated certificate.

## Known gaps (don't assume these are done)

- No rate limiting, no request logging middleware, no graceful shutdown.
- No persistence at all: signing key, refresh tokens, and topics are in memory or hardcoded.
- `production` in the iOS `APIEnvironment` points at a placeholder host; there is no deployment.
