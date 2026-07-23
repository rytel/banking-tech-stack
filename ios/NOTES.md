# Tuist notes — Day 2

Module dependency graph, generated with `tuist graph --format png --output-path .`:

![module graph](graph.png)

## What Tuist gives beyond plain SPM

- **Project generation from a typed manifest.** `Project.swift` / `Workspace.swift` are Swift,
  type-checked, with autocomplete. SPM's `Package.swift` can describe modules too, but it wasn't
  designed to generate a full Xcode app project (build settings, schemes, Info.plist wiring) —
  Tuist generates a real `.xcworkspace`/`.xcodeproj` from the declared graph.
- **No `.xcodeproj` merge conflicts.** The generated project files are gitignored
  (`*.xcodeproj`, `*.xcworkspace`) and rebuilt with `tuist generate`. Nobody hand-edits a pbxproj,
  so there's nothing to merge-conflict on.
- **Binary module caching (`tuist cache`).** Content-hash-based binary substitution per target —
  if a module's sources and dependencies haven't changed, `tuist generate` can drop in a
  prebuilt binary instead of recompiling it. Plain SPM has no first-party equivalent for this;
  Xcode's own DerivedData caching isn't shareable across machines/CI the same way.
  Note: the shared/remote cache needs a (free-tier) Tuist account; local generation still
  benefits from cache substitution without one.
- **`tuist graph` as a live architecture check.** The diagram above is generated straight from
  the manifests — if a `Feature → Feature` edge is ever accidentally introduced, it becomes
  visible immediately, instead of hiding in a flat SPM package graph.

## Architecture decisions worth being able to defend

- **Dependency rule: `Features → Core` only, never `Feature → Feature`.** Enforced structurally —
  a Feature's `Project.swift` simply never lists another Feature as a dependency. `App` is the
  only module allowed to depend on more than one Feature; it composes them. This is the concrete
  answer to "how do you avoid a god module": the rule isn't a convention someone has to remember,
  it's what the manifests allow you to declare.
- **Repository protocols live in `Core/Models`, not per-feature `Domain/` folders.** Textbook
  Dependency Inversion would put the protocol next to the feature that uses it. But the module
  rule (`Features → Core` only) means `Core/Networking` — the concrete implementer — can never
  depend on a Feature module to see its protocol. `Core/Models` is the one module both a Feature
  (consumer) and `Core/Networking` (implementer) already depend on, so that's where the contract
  has to live. `App` is what wires the concrete `Core/Networking` type into each Feature's use
  case at startup (see `CompositionRoot.swift`). Worth stating explicitly in an interview: it's a
  deliberate trade-off between "protocol next to its feature" and "module graph stays acyclic",
  not an oversight.
- **Deployment target: iOS 26.** No backward-compatibility need for a training project running
  on a personal Mac/simulator, so the target is set to whatever Xcode currently ships
  (Xcode 26.6) to use the newest APIs without `@available` gymnastics.
- **Swift 6 strict concurrency deliberately NOT enabled yet.** All 8 modules build today in
  default (Swift 5) language mode, no `Sendable`/`@MainActor` anywhere. That's scheduled for
  Day 3, once there's real async code to make correct — turning it on today would either force
  writing concurrency-aware code prematurely on empty stubs, or do nothing observable. Keeping it
  off now sets up a clean "before/after" diff to talk through on Day 3.
- **Test framework split by layer, not random.** `Core/*` test targets use XCTest,
  `Features/*` and `App` use Swift Testing (`@Test`/`#expect`). This is set up now so Day 6's
  planned XCTest-vs-Swift-Testing comparison has two real, pre-existing examples instead of one
  built for the occasion.

## Commands used

```bash
tuist generate --no-open   # regenerate the workspace after any manifest change
tuist build                # build every module + the app in dependency order
tuist test                 # run all 8 test targets
tuist graph --format png --output-path .   # this file's diagram
```
