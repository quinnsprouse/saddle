Agent-ready starter for native iOS apps: SwiftUI on Swift 6, local Swift packages, a Tuist-generated workspace, and guardrails that fail mechanically.

## Commands

- `mise run setup` installs the Git hooks and generates the Xcode workspace. Run it after cloning or after `git init`.
- `mise run dev` builds and launches the app on the pinned simulator. Add `-- --screenshot .scratch/screen.png` to see the result.
- `mise run check` runs the toolchain doctor, the settings contract, hook tests, swift-format, SwiftLint, the policy checker, package tests, and the simulator build. Run it while you work. The Stop hook runs it too.
- `mise run check:push` adds the Release build, UI journeys and accessibility audits, Periphery, dependency inspection, and Thread Sanitizer. The pre-push hook runs it.
- `mise run check:ci` adds the template contract on a fresh copy of the staged files. Stage your changes first.
- `mise run perf -- --save NAME` and `mise run perf -- --compare NAME` measure launch, scroll, and search in Release and compare against a baseline.
- `mise run doctor` explains setup problems, with a fix for each.

## Rules

- **Fix the cause the diagnostic names.** Warnings are errors. Never suppress a rule inline: `swiftlint:disable`, `swift-format-ignore`, and `periphery:ignore` fail the policy check. If a minimal example proves a rule wrong for a directory, add an allowance with a `why` to `policy.json`. A person approves that edit.
- **No comments.** Say it in code: a clearer name, a smaller function, a type. A `// why:` comment of 6 to 30 words is a last resort, only for a constraint outside the code that you can't fix, such as an SDK bug.
- **Keep the layers.** Domain holds types, logic, and ports. Services is the only module that touches files, the network, clocks, defaults, or the environment. Features depend on Domain and DesignSystem, never Services. The App target wires them together.
- **Own concurrency explicitly.** UI modules run on the main actor by default. Move heavy work off it with `@concurrent` functions or actors, check cancellation in long loops, and drop stale results.
- **Use Observation and stable identity.** `@Observable` models, `.task` for async work tied to a view, no `AnyView`, and DesignSystem tokens instead of raw colors and sizes.
- **Test behavior through public API.** Package tests use the public API only, with no `@testable`. Journeys and accessibility audits live in `App/UITests/`. Fix what an audit reports instead of filtering it.
- **Measure performance changes.** Save a baseline before a change that could be slower, compare after, and never raise a tolerance to pass. See [Performance](docs/agents/PERFORMANCE.md).
- **Don't edit generated files.** The Xcode project and workspace come from `Project.swift`. Change the manifest and run `mise run generate`.
- **No new docs.** `docs/agents/` holds the guides. Plans, notes, screenshots, traces, and experiments go in `.scratch/`.
- **Commits** follow Conventional Commits, `type(scope): description`, at most 100 characters, with no Co-Authored-By trailer.

## What you need from me

- End every turn where you're blocked on me, or where the next step needs me, with a short "**What I need from you**" section. Number the items, one concrete action each: exactly what to do, where (which app, site, file, or person), and what to send back. For example, "In Xcode, open Settings > Accounts, add your Apple ID, and send me the team ID", not "I need signing set up".
- If there are several, put the quickest or most blocking one first, and say what you'll get on with in the meantime.
- If you don't need anything from me, say "Nothing needed from you right now".
- Never bury a request for me in the middle of a long update.

## Guides

Open one when the task touches it:

- [Architecture](docs/agents/ARCHITECTURE.md): modules, ports, adding a module, concurrency, and dependencies.
- [SwiftUI](docs/agents/SWIFTUI.md): state, async work, lists, the design system, accessibility, and localization.
- [Testing](docs/agents/TESTING.md): which test to write, UI journeys, the tiers, and the hooks.
- [Performance](docs/agents/PERFORMANCE.md): measuring, baselines, comparisons, profiling, and performance rules.
- [Guardrails](docs/agents/GUARDRAILS.md): the compiler settings, lint, policy rules, and what to do when a rule is wrong.
- [Toolchain](docs/agents/TOOLCHAIN.md): pins, moving to a new Xcode or iOS release, the simulator, Xcode agent tools, and CI.
