# Components

Which control to use, how DesignSystem components work, and how to add one. Read [GUI.md](../GUI.md) first.

## Choose in this order

1. **A system component.** SwiftUI's components carry accessibility, Dynamic Type, Liquid Glass, keyboard support, and iPhone Duo layout with them. Reach for these first:
   - Structure: `NavigationSplitView`, `NavigationStack`, `TabView`, `List`, `Form`, `Section`, sheets, and `ScrollView`.
   - Content: `LabeledContent` for a label and value, `Label` for an icon and title, `ContentUnavailableView` for empty and failed states, and `ProgressView`.
   - Controls: `Button` with a role such as `.destructive` or `.cancel`, `Toggle`, `Picker`, `Menu`, `ShareLink`, and `.searchable`.
   - Actions: toolbar items with semantic placements such as `.primaryAction` and `.cancellationAction`.
2. **A DesignSystem component.** The kit ships `Badge`, a status label: `Badge(title, tone: .caution)`.
3. **A composition in the feature**, built from the two above and the tokens. Move it into DesignSystem when a second feature needs it.

Style system components through their own API, such as `.buttonStyle(.borderedProminent)`, `.buttonStyle(.glass)`, `.listStyle(.plain)`, and `.tint(_:)`. Don't rebuild a system control from shapes to change its look.

## Build a DesignSystem component

- Make it a `public struct` that conforms to `View`, in `Packages/UI/Sources/DesignSystem/`.
- Take content and meaning in its initializer, such as a `LocalizedStringResource` title and a `Tone`. Don't take colors, sizes, or fonts. The component owns its appearance.
- Use tokens for every value, and `@ScaledMetric` for dimensions that should grow with text.
- Give it a single accessibility element with a label, or let its children speak in a sensible order. Hide decorative parts with `.accessibilityHidden(true)`.
- Check that it works in light and dark appearance, at the largest accessibility text size, and in a right-to-left language.
- Give it a consumer in the same change. Periphery fails on a component nothing uses.

## States and behavior

- Give a destructive action the `.destructive` role and confirm it when it can't be undone.
- Disable a control that can't act with `.disabled(_:)`, and say why nearby when the reason isn't obvious.
- Give feedback for a state change a person caused with `.sensoryFeedback(_:trigger:)`.
- Give journey targets an `accessibilityIdentifier`, as `trail-list` and `favorite-button` show. Select by label when the label is stable and visible.
