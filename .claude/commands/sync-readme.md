---
description: Check README.md against ios/CLAUDE.md and backend/CLAUDE.md and reconcile drift
allowed-tools: Read, Grep, Glob, Edit
---

`README.md` is written for a human reader and repeats parts of the two `CLAUDE.md` files. Those
files are the source of truth — when they disagree with the README, the README is stale, not the
other way round.

1. Read `README.md`, `ios/CLAUDE.md`, and `backend/CLAUDE.md`.
2. Compare, in particular:
   - The module table (`ios/CLAUDE.md`) against the module table in `README.md`'s iOS section —
     same modules, same one-line purpose.
   - The "Current status" / feature-highlights prose in `README.md` against what the two
     `CLAUDE.md` files say is actually implemented (don't let the README claim something that a
     `CLAUDE.md` "known gaps" section says isn't done yet, or vice versa).
   - Commands shown in `README.md` (`tuist build`, `go run ./cmd/server`, etc.) against the
     `## Commands` sections in the two `CLAUDE.md` files.
   - Endpoint list and auth model description, if `README.md` mentions them, against
     `backend/CLAUDE.md`.
3. For every discrepancy found, edit `README.md` to match the `CLAUDE.md` files — do not edit the
   `CLAUDE.md` files to match the README.
4. If a module or endpoint exists in the code but isn't mentioned in either `CLAUDE.md` file,
   flag it instead of guessing — that's a gap in the source of truth, not just the README.

Report a short list of what was out of sync and what you changed. If nothing was out of sync,
say so.
