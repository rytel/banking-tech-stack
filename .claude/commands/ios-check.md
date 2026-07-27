---
description: Regenerate the Tuist workspace, build, and run the iOS tests
argument-hint: "[scheme name, e.g. CoreNetworkingTests — omit to test everything]"
allowed-tools: Bash(tuist generate:*), Bash(tuist build:*), Bash(tuist test:*), Read, Edit, Grep, Glob
---

Verify the iOS side. Run from the `ios/` directory, in this order, and stop at the first failure:

1. `tuist generate --no-open` — needed after any change to `Project.swift`, `Workspace.swift`,
   or `Tuist/ProjectDescriptionHelpers/`. Safe to run even if nothing changed.
2. `tuist build`
3. `tuist test $ARGUMENTS` — with no argument this runs every test target.

Rules for this loop:

- Do **not** pass `-derivedDataPath build` or otherwise write build output into the repository.
- If the build fails, read the actual error and fix the source. Never hand-edit `.xcodeproj` or
  `.xcworkspace` — they are generated; change `Project.swift` and regenerate.
- `AppUITests` needs the backend running (`/backend-up`) and hits the real network. If it is the
  only failing target and the backend is down, say so instead of "fixing" the test.
- Report at the end: which step failed, or that build and all tests passed.
