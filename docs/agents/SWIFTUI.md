# SwiftUI

## State

- Models are `@Observable` final classes. A view that owns its model keeps it in `@State`. A view that edits a model it was given uses `@Bindable`. Models shared across a subtree travel through `@Environment`.
- Observation tracks each property a view reads, and re-renders the view only when one of those changes. Keep `body` cheap. Pass rows plain values, as `TrailRow(trail:isFavorite:)` does, so one change doesn't re-render unrelated rows.
- Mark model properties that no view reads `@ObservationIgnored`.

## Async work

- Start work tied to a view with `.task { }`, or `.task(id: value) { }` to restart it when the value changes. SwiftUI cancels both when the view goes away. Policy rejects a `Task` started in `.onAppear`.
- Search, decoding, sorting, and file work run off the main actor. See [Architecture](ARCHITECTURE.md#concurrency).

## Lists and identity

- Use `List` or a lazy stack for long content. Give items stable `id`s. Never use array indices or a `UUID()` made during render.
- Keep row views small and concrete. `AnyView` hides identity from SwiftUI and fails the policy check. Use `@ViewBuilder` or a `switch` over concrete views.

## Adaptive layout and iPhone Duo

iPhone Duo folds between a small outer display and a large inner one, and the app resizes on every open, close, rotation, and fold. Build for a continuum of sizes:

- Branch on `horizontalSizeClass` and `verticalSizeClass`. The outer display behaves like other iPhones; the inner display is regular in both directions. Policy rejects `UIScreen.main`, device orientation, and idiom checks.
- Use containers that adapt: `NavigationSplitView` (as `LibraryView` does, with `NavigationLink(value:)` rows in a `List(selection:)`), `TabView` with `defaultTabBarPlacement(.sidebar)`, sheets, and `ViewThatFits`. Don't hard-code widths sized for one iPhone.
- Keep interactive content inside the safe area and handle each edge on its own. Duo's insets are asymmetric.
- Give every toolbar button a title and an icon, as `Button(_:systemImage:action:)`. On Duo, toolbars can lay out vertically and use the title. Prefer semantic placements such as `.primaryAction` and `.cancellationAction`.
- Use `ConcentricRectangle` to match the display's corners.
- The iOS 27.1 SDK adds four Duo APIs. Reach for them only when the containers above aren't enough:
  - `reservedRegions(kind:options:layoutDirectionBehavior:)` returns the `ReservedRegion`s, `.occlusion` or `.division`, that custom UI must avoid near system UI and the fold.
  - `ArrangementView` lays out two regions, with the `.split` or `.overlay` style.
  - `onHingeChange(isEnabled:_:)` reports a `DeviceHingeContext` whose hinge is `.closed`, `.partiallyOpen`, or `.fullyOpen`. Use it for optional effects, never for layout, and never lay out from `angle`.
  - `toolbarVerticalBehavior(.disabled)` keeps one screen's toolbar horizontal. Pick it once per screen.
- These APIs are `@available(anyAppleOS 27.1, *)`, and the deployment target is 27.0, so the app still runs on iPhones and iPads that haven't reached 27.1. Guard each use with `if #available(iOS 27.1, *)`.
- The journeys run on the iPhone Duo simulator, which boots on its outer display. Neither XCTest nor `simctl` can fold it yet, so check each layout change by hand: run `mise run dev -- --open`, then open, fold, and rotate the device in Device Hub while the app runs, and check that state survives each change. The preview canvas's Display override shows the other display. The `swiftui-pro` skill and Xcode's App Resizability skill both review resizability.

## Design system

- Screens use DesignSystem tokens and Dynamic Type text styles such as `.headline` and `.subheadline`. Raw `Color(red:)`, `.system(size:)`, and font sizes are allowed only in DesignSystem.
- Scale custom dimensions with `@ScaledMetric`, as `Badge` does for its dot.
- Use `Palette.secondaryText` for secondary text. The system `.secondary` color falls below the accessibility audit's contrast threshold for small text.

## Accessibility

- Every control has a label. Buttons get a title, even when only the icon shows. Rows combine their children with `.accessibilityElement(children: .combine)`.
- Give elements that a UI test needs an `accessibilityIdentifier`.
- `App/UITests/AccessibilityAuditTests.swift` audits contrast, hit areas, labels, and Dynamic Type at the largest size. Add an audit for each new screen. Fix what it reports instead of filtering issues in a handler.

## Localization

Package code reads strings from its own bundle: `Text("Trails", bundle: .module)` and `String(localized: "…", bundle: .module)`. Each feature keeps its catalog at `Sources/<Module>/Resources/Localizable.xcstrings`, and the package declares `defaultLocalization`.
