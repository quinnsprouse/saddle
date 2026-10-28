# Testing

Test what a caller or a person can observe. A test that pins internals breaks on every refactor and costs tokens to rewrite.

## Pick the test

| Change | Test | Where |
| --- | --- | --- |
| Domain logic or a Service | Swift Testing through the module's public API | `Packages/<Package>/Tests/<Module>Tests/` |
| A screen or user journey | XCUITest | `App/UITests/` |
| A new screen's accessibility | `performAccessibilityAudit()` | `App/UITests/AccessibilityAuditTests.swift` |
| A performance-sensitive path | XCTest metrics, run with `mise run perf` | `App/PerformanceTests/` (see [Performance](PERFORMANCE.md)) |
| A policy rule | accepted and rejected cases | `Tools/Tests/PolicyKitTests/` |
| A hook | a case in `scripts/test-hooks.mjs` | |

UI modules have no unit tests: what they do is what a person sees, so a journey covers it. The guard refuses test files outside these directories, and policy refuses `@testable import`. If a test seems to need internals, the module's public API is missing something.

**The check:** change the internals without changing the behavior. If the test fails, it tested the implementation.

## Write reliable tests

- Wait on state, never on time. Use `waitForExistence(timeout:)` in UI tests. Policy bans `Thread.sleep` and semaphores.
- Make data deterministic. The demo catalog comes from a fixed seed.
- Prove cancellation and ordering through behavior, as `TrailIndexTests.aCancelledSearchThrowsInsteadOfFinishing` does.

## UI journeys

- Launch with `XCUIApplication.isolated()`. It points `APP_DATA_DIRECTORY` at a new temporary directory, so every launch starts with empty storage. Pass the same directory twice to test persistence across launches.
- Select elements by accessibility identifier or label.
- Submit or dismiss the keyboard before an audit. System keyboard elements fail it.
- `check:push` runs the journeys one at a time on the simulator from `toolchain.json`. Results land in `.scratch/results/ui.xcresult`. Open it in Xcode for screenshots and timelines.

## Tiers

| Command | Adds | Runs from |
| --- | --- | --- |
| `mise run check` | doctor, contract, hook tests, swift-format, SwiftLint, policy, policy tests, Core tests, generate, simulator build | you, and the Stop hook |
| `mise run check:push` | Release build, UI journeys and audits, Periphery, `tuist inspect dependencies`, Core tests under Thread Sanitizer | the pre-push hook |
| `mise run check:ci` | the template contract on a fresh copy of the staged files, including a rename | CI |

Each tier keeps going after a failure. It skips only the steps that depend on a failed one, such as the build after a failed generate. It prints one line per diagnostic and writes the full output to `.scratch/logs/`.

## Hooks that check your work

- `guard.mjs` refuses edits to generated files and `Package.resolved`, new tests and docs outside their homes, hook bypasses, force pushes, flags that silence warnings, and Homebrew installs of pinned tools. It asks a person before an edit to a check file. It reads raw command text, so a heredoc that mentions a blocked flag is blocked too. Write that content with a file tool.
- `post-edit.mjs` formats each Swift file an edit tool writes, then lints it. Once `check` has built the policy binary, it runs policy on the file too. Shell edits skip it.
- `stop.mjs` runs `check` before the turn ends and sends you back once if it fails. If you stop again without changing anything, it reminds you instead of blocking. It caches by diff, so an unchanged tree isn't checked twice.
- `session-start.mjs` runs the doctor.
- Git hooks in `.githooks/`: commit-msg enforces Conventional Commits, pre-commit format-checks staged Swift files, and pre-push runs `check:push`.
