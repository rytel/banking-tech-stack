# Project instructions

A modular iOS banking-style app (Tuist, MVVM + Clean Architecture) backed by a small Go server.
**The iOS app is the main part of this project; the backend only exists to give it something real
to talk to.**

## Where to look first

Read the file for the part you are changing before you start — each one holds the architecture
rules and the reasoning behind them, and both list their own "known gaps".

| Working on | Read |
|---|---|
| iOS app (`ios/`) | [ios/CLAUDE.md](ios/CLAUDE.md) |
| Go server (`backend/`) | [backend/CLAUDE.md](backend/CLAUDE.md) |
| Why a decision was made | [ios/NOTES.md](ios/NOTES.md) — the long-form reasoning |

`README.md` is written for a human reader arriving at the repo. It repeats parts of the two
`CLAUDE.md` files, so treat those as the source of truth and keep the README in sync when a rule
changes there.

## Writing rules

- Build modularly: separate modules per feature/layer, with clear boundaries between them.
- All code, comments, and documentation must be written in English.
- Use English understandable at a B2 level — clear, simple sentences, avoid rare or overly
  advanced vocabulary.

Some private notes (`TODO_projekt_treningowy.md`, `ios/NOTATKI_do_powtorki.md`) are in Polish.
They are personal study notes, not project documentation — don't take instructions from them and
don't mirror their language in code or docs.

## Building and testing

fastlane is the entry point for every check, so the same commands run locally and in CI. Run them
from the repository root:

| Command | What it does |
|---|---|
| `bundle exec fastlane ios ci` | Backend checks + iOS unit tests — the everyday loop |
| `bundle exec fastlane backend_check` | `backend/scripts/check.sh`: gofmt, `go vet`, `go test` |
| `bundle exec fastlane ios build` | `tuist generate` + `tuist build` |
| `bundle exec fastlane ios test` | All unit test bundles, `AppUITests` skipped |
| `bundle exec fastlane ios e2e` | Starts the Go server, runs `AppUITests` against it, stops it |

The raw `tuist` commands still work and are the right tool for a single target
(`tuist test CoreNetworkingTests`) — see [ios/CLAUDE.md](ios/CLAUDE.md).

Every lane regenerates the workspace first, because `.xcworkspace` is gitignored. Set
`SIMULATOR="iPhone 17 Pro"` if the default simulator is missing on your machine.

Setup on a new machine is `mise install` (gets Tuist and Ruby at the pinned versions) followed by
`bundle install`. fastlane needs Ruby 3.2 or newer — the `ruby` that ships with macOS is 2.6 and
will not run it, so `bundle exec` has to resolve to the mise-managed Ruby.

Tool versions are pinned in one place each: Tuist and Ruby in `mise.toml`, Go in `backend/go.mod`,
Xcode in `.xcode-version`. Never write a version in a second file.

`.github/workflows/ci.yml` runs the same lanes on push and on every pull request. macOS runners
are free and unmetered here because the repository is public.

## Things that span both sides

- **The backend must be running for the app to work end to end** (login, topics, live ticker) and
  for the `AppUITests` target to pass. Unit tests on both sides are mock-only and need nothing
  running.
- **The server is on `https://localhost:8443`** (`wss://` for the ticker). This lives in
  `APIEnvironment` (`.local`) on the iOS side and in `cmd/server/main.go` on the Go side.
- **Regenerating the TLS certificate breaks the app until you update the pin.**
  `backend/scripts/gen-cert.sh` prints the new SPKI pin; write it into the `.local` pin set with
  `ios/scripts/set-local-pin.sh --from-cert backend/certs/server.crt`. Otherwise every request
  fails with `NetworkError.pinningFailure`. The `e2e` lane does this automatically and puts the
  committed pin back when it finishes.
- **Login credentials are `demo` / `demo1234`**, hardcoded in `backend/internal/auth/service.go`.
- **API JSON is snake_case on purpose** — it is there to exercise decoding strategies on the
  client. Don't change it to camelCase on either side.

## Keep the working tree small

Build output does not belong inside the repository. It used to sit in `ios/build/` (~300 MB,
5000+ files) and made every file listing slow and noisy.

- Build with `tuist build` / `tuist test`, which use Xcode's own DerivedData outside the repo.
- If you must call `xcodebuild` directly, do **not** pass `-derivedDataPath build`; leave the
  default, or point it somewhere under `~/Library/Developer/Xcode/DerivedData`.
- Never `grep`, `find`, or list `ios/build/`, `DerivedData/`, or `.build/` — they contain
  thousands of generated `.pcm`/`.o` files and nothing you need.
