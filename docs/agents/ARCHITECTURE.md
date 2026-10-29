# Architecture

## Modules

| Module | Lives in | Depends on | Owns |
| --- | --- | --- | --- |
| Domain | `Packages/Core` | nothing | Value types, pure logic, and ports: protocols for everything outside the process |
| Services | `Packages/Core` | Domain | The ports' live implementations: files, network, defaults, environment |
| DesignSystem | `Packages/UI` | nothing | Tokens (`Spacing`, `Palette`, `Tone`) and small components |
| LibraryFeature | `Packages/UI` | Domain, DesignSystem | One feature's views and its `@Observable` model |
| App | `Project.swift`, `App/Sources` | everything | The composition root: it builds Services and passes them to features |

A feature never imports Services. It takes a port, such as `any FavoritesStore`, and `App/Sources/Composition.swift` passes the live implementation. Journeys steer the live implementations through launch environment values such as `APP_DATA_DIRECTORY`.

Core builds on the Mac with an explicit-import check, so keep it free of UIKit and SwiftUI. Packages/UI runs on the main actor by default.

## Add a module

1. Add the target to the Package.swift that matches its layer, with `swiftSettings: strict`. A new package under `Packages/` needs the same `strict` list. `mise run check` names any setting you missed.
2. Declare every dependency. Core builds with `--explicit-target-dependency-import-check error`, and `check:push` runs `tuist inspect dependencies`.
3. If the app uses the module directly, add its product to the App target's dependencies in `Project.swift`.
4. If the module implements ports, add it to the `world-access` allowance in `policy.json`.

## Concurrency

- The App and Packages/UI run on the main actor. Core is nonisolated.
- Move expensive work off the main actor with a `@concurrent` function (`LibraryModel.search`) or an actor (`FileFavoritesStore`). Pass values in and return values out.
- Long loops check cancellation. `TrailIndex.search` checks every 1,024 entries, and `LibraryModel` drops results for a query that has since changed.
- Replace obsolete work instead of piling it up. `LibraryModel.toggleFavorite` cancels the previous save, waits for it, and then writes, so saves land in order.
- Bound queues, caches, and task lifetimes. Tie work to a view with `.task` so SwiftUI cancels it.

## Dependencies

Add a remote package to the Package.swift of the module that needs it, pinned with `exact:`. The contract rejects version ranges. Prefer Apple frameworks: each dependency costs launch time and binary size, so measure it before you keep it.
