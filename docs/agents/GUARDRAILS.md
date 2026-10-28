# Guardrails

From strongest to weakest:

1. **The compiler.** Swift 6 language mode with complete concurrency checking, warnings as errors, strict memory safety, `ExistentialAny`, `InternalImportsByDefault`, `MemberImportVisibility`, approachable concurrency, and a 150 ms budget for type-checking any function or expression. `scripts/contract.mjs` fails `check` if a package target drops warnings as errors, strict memory safety, or an upcoming feature, if a UI target drops main-actor isolation, if `BuildSettings.swift` drops a strict Xcode key, or if a setting applies to only one configuration. It doesn't check the type-checking budget flags.
2. **The module graph.** A module sees only what its Package.swift declares. Features can't reach Services.
3. **SwiftLint** (`.swiftlint.yml`). Strict, with curated opt-in rules and size limits: files 300 lines, functions 40, types 200, closures 30, cyclomatic complexity 10.
4. **swift-format** (`.swift-format`). Apple's formatter from the Xcode toolchain, so Xcode's Format command matches `check`.
5. **Policy** (`Tools/`, `policy.json`). Rules SwiftLint can't express, listed below.
6. **Periphery** in `check:push`. Unused code and needless `public`.
7. **Hooks.** Agent hooks give early feedback and Git hooks gate commits and pushes. Neither is a security boundary: protect `main` and require CI on the remote.

## Policy rules

| Rule | Rejects | Instead |
| --- | --- | --- |
| `comment` | any comment except `// why:` of 6 to 30 words | a clearer name, a smaller function, a type |
| `lint-escape` | `swiftlint:`, `swift-format-ignore`, `periphery:ignore` | fix the cause |
| `skipped-test` | `.disabled(...)`, `.enabled(if:)`, `XCTSkip`, `withKnownIssue` | fix or delete the test |
| `testable-import` | `@testable import` | test the public API |
| `world-access` | `URLSession`, `FileManager`, `UserDefaults`, `ProcessInfo`, `NotificationCenter`, `DispatchQueue`, `UIApplication`, `Date()`, `Date.now`, `Bundle.main` outside the allowed paths | a Domain port implemented in Services |
| `blocking-call` | `Thread.sleep`, `sleep`, semaphores, dispatch groups, `queue.sync { }` | async/await and actors |
| `concurrency-escape` | `@unchecked Sendable`, `nonisolated(unsafe)`, `unowned(unsafe)`, `@preconcurrency` | a Sendable type or an actor |
| `detached-task` | `Task.detached` | a `@concurrent` function or a task group |
| `legacy-observation` | `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject` | `@Observable` with `@State`, `@Bindable`, `@Environment` |
| `type-erased-view` | `AnyView` | `@ViewBuilder`, generics, a `switch` |
| `design-token` | raw colors and font sizes outside DesignSystem | a token or a text style |
| `print` | `print`, `debugPrint`, `dump`, `NSLog` | `os.Logger` with a privacy level |
| `on-appear-task` | a `Task` started in `.onAppear` | `.task { }` |

Policy is a tripwire, not a type system: an alias or a module-qualified name gets past it. Don't do that. Review catches it, and the next agent copies it.

## When a rule is wrong

Fix the cause first. To claim a false positive, write the smallest snippet that triggers it. Then:

- A policy rule that's wrong for a whole directory: add an allowance to `policy.json` with the rule, the paths, and a `why` of at least 6 words.
- A policy rule that misreads valid code: fix the matcher in `Tools/Sources/PolicyKit/` and add the snippet to `PolicyTests.accepted`.
- A SwiftLint rule: add a `.swiftlint.yml` to that directory that disables only that rule, after the same proof. SwiftLint applies nested configurations to the files below them.

The guard asks a person before any of these edits.

## Add a rule

When you correct the same mistake twice, make it a rule instead of more prose. Prefer a compiler setting, then a SwiftLint rule, then a policy rule. A policy rule needs rejected and accepted cases in `PolicyTests` and a message that names the fix (`Rule.message`).
