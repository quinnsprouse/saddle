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

## Design system

- Screens use DesignSystem tokens and Dynamic Type text styles such as `.headline` and `.subheadline`. Raw `Color(red:)`, `.system(size:)`, and font sizes are allowed only in DesignSystem.
- Scale custom dimensions with `@ScaledMetric`, as `Badge` does for its dot.
- Use `Palette.secondaryText` for secondary text. The system `.secondary` color falls below the accessibility audit's contrast threshold for small text.

## Accessibility

- Every control has a label. Icons get `.accessibilityLabel`. Rows combine their children with `.accessibilityElement(children: .combine)`.
- Give elements that a UI test needs an `accessibilityIdentifier`.
- `App/UITests/AccessibilityAuditTests.swift` audits contrast, hit areas, labels, and Dynamic Type at the largest size. Add an audit for each new screen. Fix what it reports instead of filtering issues in a handler.

## Localization

Package code reads strings from its own bundle: `Text("Trails", bundle: .module)` and `String(localized: "…", bundle: .module)`. Each feature keeps its catalog at `Sources/<Module>/Resources/Localizable.xcstrings`, and the package declares `defaultLocalization`.
