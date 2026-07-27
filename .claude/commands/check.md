---
description: Run the full verification loop for both sides — Go tests, then iOS build and tests
allowed-tools: Bash(bundle exec fastlane:*), Bash(gofmt:*), Read, Edit, Grep, Glob
---

Verify the whole repository with the `ci` lane, run from the repository root:

```
bundle exec fastlane ios ci
```

That is backend checks (`gofmt`, `go vet`, `go test`) followed by the iOS unit tests. The lane
regenerates the Tuist workspace itself, so it works on a fresh clone.

`AppUITests` is deliberately not part of this lane — it needs a running backend. Use
`/smoke-test` for that.

Rules for this loop:

- Never write build output into the repository (no `-derivedDataPath build`), and never hand-edit
  generated `.xcodeproj` / `.xcworkspace` files — change `Project.swift` and regenerate.
- If the build fails, read the actual error and fix the source.
- If the failure is a missing simulator, rerun with `SIMULATOR="<device name>"` rather than
  changing the Fastfile.

Finish with a short summary: what passed, what failed, and the actual error for each failure.
