# Testing

Test what a person can observe, end to end. App code has no unit tests. A unit test pins the shape code has today, so it breaks on every refactor and costs tokens to rewrite, while a journey keeps proving the app works.

## Pick the test

| Change | Test | Where |
| --- | --- | --- |
| Any behavior a person sees | an XCUITest journey | `App/UITests/` |
| A new screen's accessibility | `performAccessibilityAudit()` | `App/UITests/AccessibilityAuditTests.swift` |
| A performance-sensitive path | XCTest metrics, run with `mise run perf` | `App/PerformanceTests/` (see [Performance](PERFORMANCE.md)) |
| A policy rule | accepted and rejected cases | `Tools/Tests/PolicyKitTests/` |
| A hook or script check | a case in `scripts/test-hooks.mjs` | |

The checks hold this mechanically. The contract rejects a test target in an app package, policy rejects `import Testing` and `import XCTest` outside these directories, and the guard refuses new test files elsewhere.

Cover failure paths through the app too. `testACorruptFavoritesFileShowsTheFailureState` writes a broken file into the journey's data directory and checks the screen a person would see.

**The check:** change the internals without changing what a person sees. If a test fails, it tested the implementation.

## Write reliable journeys

- Launch with `XCUIApplication.isolated()`. It points `APP_DATA_DIRECTORY` at a new temporary directory, so every launch starts with empty storage. Pass the same directory twice to test persistence across launches, or write files into it first to set up a state.
- Select elements by accessibility identifier or label. If a query can't find an element, VoiceOver probably can't either: fix the element's accessibility first.
- Wait on state, never on time. Use `waitForExistence(timeout:)`. Policy bans `Thread.sleep` and semaphores.
- Submit or dismiss the keyboard before an audit. System keyboard elements fail it.
- Keep data deterministic. The demo catalog comes from a fixed seed.

## Thread Sanitizer

`check:push` builds the app with Thread Sanitizer and runs every journey against that build. `XCUIApplication.isolated()` sets `halt_on_error`, so a data race crashes the app and fails the journey. Results land in `.scratch/results/ui.xcresult`. Open it in Xcode for screenshots, timelines, and sanitizer reports.

## Tiers

| Command | Adds | Runs from |
| --- | --- | --- |
| `mise run check` | doctor, contract, hook tests, comments, theme reference, swift-format, SwiftLint, policy, policy tests, import check, generate, simulator build | you, and the Stop hook |
| `mise run check:push` | Release build, SwiftLint analyzer, journeys and audits under Thread Sanitizer, Periphery, `tuist inspect dependencies` | the pre-push hook |
| `mise run check:ci` | the template contract on a fresh copy of the staged files, including a rename | CI, in four parallel lanes |

Each tier keeps going after a failure. It skips only the steps that depend on a failed one, such as the build after a failed generate. It prints one line per diagnostic and writes the full output to `.scratch/logs/`.

## Hooks that check your work

- `guard.mjs` refuses edits to generated files, `Package.resolved`, and vendored skills, new tests and docs outside their homes, hook bypasses, force pushes, flags that silence warnings, and Homebrew installs of pinned tools. It asks a person before an edit to a check file. It reads raw command text, so a heredoc that mentions a blocked flag is blocked too. Write that content with a file tool.
- `post-edit.mjs` formats each Swift file an edit tool writes, then lints it. Once `check` has built the policy binary, it runs policy on the file too. Shell edits skip it.
- `stop.mjs` runs `check` before the turn ends and sends you back once if it fails. If you stop again without changing anything, it reminds you instead of blocking. It caches by diff, so an unchanged tree isn't checked twice.
- `session-start.mjs` runs the doctor.
- Git hooks in `.githooks/`: commit-msg enforces Conventional Commits, pre-commit format-checks staged Swift files, and pre-push runs `check:push`.
