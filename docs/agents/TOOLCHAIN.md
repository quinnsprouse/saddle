# Toolchain

## Pins

- `toolchain.json` pins Xcode, Swift, the iOS deployment target, and the simulator. The doctor checks the installed Xcode and Swift against it, and the contract makes the iOS platform of each package in `Packages/` and `Identity.deploymentTarget` match its `ios` value.
- `mise.toml` pins Node, Tuist, SwiftLint, and Periphery, and defines the tasks. swift-format ships with Xcode.
- `Tools/Package.resolved` pins swift-syntax. Remote packages use `exact:` versions.

## Move to a new Xcode or iOS release

1. Install the new Xcode, select it with `sudo xcode-select -s /Applications/Xcode.app`, and install its simulator runtime with `xcodebuild -downloadPlatform iOS`.
2. Update `xcode`, `swift`, and `ios` in `toolchain.json`.
3. Set the same iOS version in each `Packages/*/Package.swift` and in `Tuist/ProjectDescriptionHelpers/Identity.swift`. `mise run check` names any file you missed.
4. Move swift-syntax in `Tools/Package.swift` to the release for the new Swift, then run `swift package update --package-path Tools`.
5. Run `mise run check:ci` and fix new diagnostics at their source.

## Workspace

Tuist generates `<App>.xcworkspace` from `Project.swift` and `Tuist/ProjectDescriptionHelpers/`. Git ignores the generated files. Run `mise run generate` after changing a manifest, then open the workspace with `xed .`.

`mise run rename -- <AppName> <bundle.id>` changes the app's name and bundle identifier in `Identity.swift` and deletes the old workspace.

## Simulator

`mise run dev` builds Debug for the simulator named in `toolchain.json`, boots it, installs the app, and launches it. `--screenshot <path>` saves a screenshot after `--wait` seconds (default 3). `--open` shows Simulator.app.

## Agent tools for Xcode

- **XcodeBuildMCP**, pinned in `.mcp.json` and `.codex/config.toml`: build, run, tap, type, take screenshots, read the view hierarchy, and debug on the simulator.
- **Xcode's MCP server**, in Xcode 26.3 and later: build logs, tests, previews, and Apple documentation from a running Xcode. Turn on Xcode > Settings > Intelligence > Xcode Tools, then run `claude mcp add xcode -- xcrun mcpbridge` or `codex mcp add xcode -- xcrun mcpbridge`.

## CI

`.github/workflows/ci.yml` runs `mise run check:ci` on a macOS runner with the Xcode from `toolchain.json`. Each action is pinned to a commit SHA, and Dependabot updates the actions and swift-syntax. macOS runner minutes cost several times Linux minutes, so run `check:push` locally and let CI confirm.
