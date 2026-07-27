---
description: Add a new Tuist module (Core or Feature) following the project's conventions
argument-hint: "<Core|Feature> <ModuleName> [dependencies]"
allowed-tools: Bash(tuist generate:*), Bash(tuist build:*), Bash(tuist test:*), Read, Write, Edit, Grep, Glob
---

Add a new module: $ARGUMENTS

Follow the existing shape exactly — copy `Projects/Core/RASP` (no dependencies) or
`Projects/Features/TopicDetail` (with dependencies) as the template.

1. Create `ios/Projects/<Core|Features>/<Name>/` with `Sources/` and `Tests/` subfolders.
   Tuist uses `buildableFolders`, so files are picked up automatically — no target membership
   to maintain.
2. Write `Project.swift` with just the `Project.module(...)` call:
   - `name` is `Core<Name>` or `Feature<Name>` (the prefix is part of the target name).
   - `bundleIdSuffix` is lowercased, e.g. `core.rasp`, `features.topicdetail`.
   - `dependencies` uses the `.core("Models")` / `.feature("Auth")` helpers.
   - Set `needsTestHost: true` only if the tests touch the real Keychain.
3. **Respect the hard dependency rule: a Feature must never depend on another Feature.** Only
   `App` may depend on more than one Feature, and it wires them in
   `Projects/App/Sources/CompositionRoot.swift`.
4. If the module exposes a repository, its protocol belongs in `Core/Models`, not in a feature
   `Domain/` folder — see `ios/CLAUDE.md` for why.
5. Match the testing style of the folder it lives in: XCTest under `Core/*`, Swift Testing
   (`@Test` / `#expect`) under `Features/*` and `App`. Do not unify these.
6. `Workspace.swift` uses glob patterns (`Projects/Core/**`), so a new module is picked up with
   no edit there.
7. Run `tuist generate --no-open`, then `tuist build`, then `tuist test <Name>Tests`.
8. Add the module to the tables in `ios/CLAUDE.md` and `README.md`, and regenerate the graph with
   `tuist graph --format png --output-path .`.
