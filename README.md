# Banking Tech Stack

[![CI](https://github.com/rytel/banking-tech-stack/actions/workflows/ci.yml/badge.svg)](https://github.com/rytel/banking-tech-stack/actions/workflows/ci.yml)

A modular iOS banking-style app built with MVVM + Clean Architecture and Tuist, backed by a small Go server that makes the login, topics, and live ticker flows work end to end.

**The iOS app is the main part of this project. The backend is a lightweight support service** — just enough to give the app something real to talk to.

## iOS app

- Swift 6.0, iOS 26.0+
- Workspace generated with [Tuist](https://tuist.io/) — no third-party SPM dependencies
- Architecture: `View → ViewModel → UseCase → Repository (protocol)`, following MVVM + Clean Architecture

### Module structure

The dependency rule is strict: **Features depend on Core, never on each other.** `App` is the only module allowed to depend on more than one Feature — it composes them. See [ios/NOTES.md](ios/NOTES.md) for the full reasoning behind this and other architecture decisions.

| Module | Purpose |
|---|---|
| `App` | Composition root and dependency injection |
| `Features/Auth` | Login screen (`AuthView`, `AuthViewModel`, `LoginUseCase`) |
| `Features/TopicsList` | Topic list with search, plus the live ticker |
| `Features/TopicDetail` | Topic detail screen |
| `Core/Models` | Shared domain models and repository protocols |
| `Core/Networking` | HTTP client and repository implementations |
| `Core/SecureStorage` | Token and secret storage |
| `Core/DesignSystem` | Shared UI building blocks |
| `Core/RASP` | Basic debugger/jailbreak detection |

![module graph](ios/graph.png)

### Feature highlights

- Login screen wired to a real backend (`AuthView` / `AuthViewModel` / `LoginUseCase`)
- Topic list with search
- Live ticker built on a Combine publisher wrapped around a WebSocket connection (`URLSessionWebSocketTask`)
- Swift 6 concurrency features in `Core` (`Sendable`, `@MainActor`, `Observation` framework)
- Two testing styles side by side: XCTest in `Core`, Swift Testing (`@Test`, `#expect`) in `Features` and `App`
- `MockURLProtocol` used to stub network calls in tests

### Running the app

```bash
cd ios
tuist generate --no-open
tuist build
tuist test
```

The workspace is generated, not committed, so `tuist generate` comes first on a fresh clone. The backend must be running for the app to work — login, the topics list, and the live ticker all need it.

### Current status

Core flows (login, topics, live ticker) work end to end. Token storage is in place: the refresh token is persisted in the Keychain (`ThisDeviceOnly`, so it never leaves the device via backups), the access token is kept in memory only, and a biometry-gated store (Face ID / Touch ID) is ready for the `GET /secret` value. Token refresh is serialized through a single-flight `TokenRefreshCoordinator`, so concurrent 401s trigger exactly one refresh call. TLS certificate pinning is in place: one shared `URLSession` pins the server's SPKI (public key) hash for both HTTPS and the WebSocket ticker, failing closed on any mismatch. Basic RASP checks are in place too: a `sysctl`-based debugger check and a file-heuristic jailbreak check run once at launch and log a warning if either fires — both are defense-in-depth signals, not hard barriers, and never block the app.
## Backend

A small Go service whose only job is to give the iOS app something real to call — not a project in its own right.

- Go, standard library `net/http`, plus one dependency: `github.com/coder/websocket`
- Serves HTTPS on `:8443` with a self-signed certificate
- JWT authentication signed with ES256

### Endpoints

| Endpoint | Description |
|---|---|
| `GET /health` | Health check |
| `POST /auth/login` | Returns an access token and a refresh token |
| `POST /auth/refresh` | Returns a new access token and a new refresh token |
| `GET /topics` | List of topics (supports optional `?q=` query to filter by title) |
| `GET /topics/{id}` | Topic details |
| `GET /ws/ticker` | WebSocket feed used by the iOS live ticker, one message per second |
| `GET /secret` | Example protected endpoint, requires a valid JWT |

### Running the backend

```bash
cd backend
./scripts/gen-cert.sh
go run ./cmd/server
```

## Continuous integration

Every check runs through fastlane, so CI and a local machine execute the same commands. From the repository root:

```bash
mise install     # Tuist and Ruby at the pinned versions
bundle install
bundle exec fastlane ios ci
```

fastlane needs Ruby 3.2 or newer, so the `ruby` that ships with macOS (2.6) will not do.

| Lane | What it does |
|---|---|
| `fastlane ios ci` | Backend checks + iOS unit tests — the everyday loop |
| `fastlane backend_check` | gofmt, `go vet`, `go test` |
| `fastlane ios build` | `tuist generate` + `tuist build` |
| `fastlane ios test` | All unit test bundles, `AppUITests` skipped |
| `fastlane ios e2e` | Starts the Go server, runs `AppUITests` against it, stops it |

The `e2e` lane is the interesting one: certificates are not committed, so it generates one if needed, points the app's `.local` SPKI pin at the key the running server actually serves, runs the UI tests, then stops the server and restores the committed pin. That is what makes an end-to-end run reproducible on a machine that has never seen this repository.

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs these lanes on push and on every pull request: the Go checks on Linux, the iOS tests and the end-to-end run on macOS. GitHub's macOS runners are free and unmetered for public repositories.

Tool versions are pinned one place each — Tuist and Ruby in `mise.toml`, Go in `backend/go.mod`, Xcode in `.xcode-version`.

## Repository layout

```
.
├── ios/        # iOS app (Tuist workspace, MVVM + Clean Architecture)
├── backend/    # Go server backing the app
├── fastlane/   # Build and test lanes, shared by developers and CI
└── certs/      # TLS certificate and key used by the backend (generated, not committed)
```
