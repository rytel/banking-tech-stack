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

## Things that span both sides

- **The backend must be running for the app to work end to end** (login, topics, live ticker) and
  for the `AppUITests` target to pass. Unit tests on both sides are mock-only and need nothing
  running.
- **The server is on `https://localhost:8443`** (`wss://` for the ticker). This lives in
  `APIEnvironment` (`.local`) on the iOS side and in `cmd/server/main.go` on the Go side.
- **Regenerating the TLS certificate breaks the app until you update the pin.**
  `backend/scripts/gen-cert.sh` prints the new SPKI pin; paste it into the `.local` pin set in
  `ios/Projects/Core/Networking/Sources/Pinning/PinningConfiguration.swift`. Otherwise every
  request fails with `NetworkError.pinningFailure`.
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
