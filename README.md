# Saddle 🐎

A starter for native iOS apps built with coding agents: SwiftUI on Swift 6, local Swift packages, a Tuist-generated workspace, and guardrails that fail mechanically instead of relying on prose.

Requires a Mac on macOS 26 or newer, the Xcode in [`toolchain.json`](toolchain.json), [mise](https://mise.jdx.dev), and Git.

## Quick start

```bash
mise exec node@24 -- npx degit quinnsprouse/saddle my-app
cd my-app
git init --initial-branch=main
mise trust && mise install
mise run setup
mise run rename -- MyApp com.example.myapp
mise run dev
```

`mise run setup` installs the Git hooks and generates the workspace. `mise run dev` builds the app and launches it on the simulator pinned in `toolchain.json`. Open the workspace in Xcode with `xed .`.

## What you get

- **Strict Swift 6.** Complete concurrency checking, warnings as errors, strict memory safety, `ExistentialAny`, `InternalImportsByDefault`, `MemberImportVisibility`, and type-checking time budgets. A contract test fails if a module drops warnings as errors, strict memory safety, the upcoming features, or main-actor isolation in UI.
- **Layers the compiler enforces.** Domain holds logic and ports, Services is the only module that touches the outside world, features depend on Domain and DesignSystem but never Services, and the App target is the composition root.
- **A policy checker** built on swift-syntax for what SwiftLint can't express: no comments except `// why:`, no inline lint escapes, no skipped tests or `@testable`, no blocking calls or concurrency escapes, no `AnyView` or `ObservableObject`, and design tokens instead of raw colors and sizes.
- **Behavior tests.** Swift Testing through each module's public API, XCUITest journeys with isolated storage, and accessibility audits for contrast, hit areas, labels, and Dynamic Type.
- **Performance by default.** Off-main-actor work with cancellation, signposts, MetricKit, Thread Sanitizer, and Periphery for dead code. `mise run perf` measures launch, scroll, and search in Release and compares against saved baselines.
- **Agent hooks** for Claude Code and Codex, shared in `.agents/hooks/`: a guard for risky edits and commands, formatting and lint after each edit, and a stop check that sends the agent back once when `check` fails. [XcodeBuildMCP](https://xcodebuildmcp.com) is configured for simulator control.

## Commands

| Command | Purpose |
| --- | --- |
| `mise run dev` | Build and launch on the simulator. `-- --screenshot <path>` saves a screenshot |
| `mise run check` | Doctor, settings contract, hook tests, format, lint, policy, package tests, simulator build |
| `mise run check:push` | Check plus the Release build, UI journeys and audits, dead code, dependencies, and Thread Sanitizer |
| `mise run check:ci` | Push checks plus the template contract on a fresh copy of the staged files |
| `mise run perf -- --save NAME` / `--compare NAME` | Measure launch, scroll, and search in Release, and compare against a baseline |
| `mise run fmt` | Format Swift files and apply SwiftLint autocorrections |
| `mise run generate` | Regenerate the workspace after changing `Project.swift` |
| `mise run rename -- <AppName> <bundle.id>` | Rename the app and its bundle identifier |
| `mise run doctor` | Explain setup problems, with a fix for each |

## Remove the demo

The trail library is a demo of the architecture. To start blank:

1. Delete `Packages/UI/Sources/LibraryFeature/` and its product and target in `Packages/UI/Package.swift`.
2. Delete the demo types in `Packages/Core/Sources/Domain/` and `Packages/Core/Sources/Services/`, and their tests in `Packages/Core/Tests/`. Keep `StorageLocation` if you keep file storage. A target needs at least one source file: delete any target you empty, along with its product, its test target, every `dependencies` entry that names it (Services depends on Domain), and the App's dependency on it in `Project.swift`.
3. Replace `App/Sources/Composition.swift` and the root view in `App/Sources/MainApp.swift` with your own, and remove `LibraryFeature` from the App target in `Project.swift`.
4. Replace the journeys in `App/UITests/` and the measurements in `App/PerformanceTests/` with your own.
5. Run `mise run check:push`. Periphery reports the DesignSystem tokens and helpers that only the demo used. Delete them, or use them.

## Working with agents

[AGENTS.md](AGENTS.md) is the entry point, and `CLAUDE.md` imports it for Claude Code. Focused guides live in [`docs/agents/`](docs/agents/). Claude Code runs the hooks through `.claude/settings.json`. Codex runs them through `.codex/hooks.json` after you trust the project and approve each hook in `/hooks`. Keep personal permissions in the ignored `.claude/settings.local.json`.

## Layout

- `App/`: the app target's composition root, resources, UI journeys, performance tests, and shared test support
- `Packages/Core/`: Domain and Services, built and tested on the Mac
- `Packages/UI/`: DesignSystem and features, on the main actor by default
- `Tools/`: the policy checker and its tests
- `Project.swift`, `Tuist/`: the workspace manifest, identity, and build settings
- `scripts/`: verification tiers, doctor, contract, template contract, and dev tools
- `.agents/hooks/`, `.githooks/`: agent and Git hooks
- `docs/agents/`: implementation guides
- `.scratch/`: ignored logs, results, screenshots, and experiments

## License

[MIT](LICENSE)
