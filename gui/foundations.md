# Foundations

The shared vocabulary for color, type, spacing, shape, depth, icons, motion, and states. Read [GUI.md](../GUI.md) first. Values live in the [theme reference](theme.md).

## Color

Start with the system's semantic styles: `.primary` for text, `.tint` for the accent, `.background` for screens, `.fill.secondary` and `.fill.tertiary` for quiet fills, and `.separator` for edges. They adapt to Dark Mode, Increase Contrast, and Liquid Glass without any work from you.

`Palette` holds the colors the system leaves to the app:

- `Palette.secondaryText` for secondary text. The system `.secondary` style falls below the accessibility audit's contrast threshold for small text.
- `Palette.favorite` for the favorite star.
- `Palette.success`, `Palette.warning`, and `Palette.critical` for status. Features reach them through `Tone`, as `Badge` does, rather than by name.

The accent color is `AccentColor` in `App/Resources/Assets.xcassets`. Read it as `.tint`.

Palette builds on SwiftUI's named colors, such as `Color.yellow`, because they adapt to each appearance. For a brand color, add a color set with Dark and High Contrast appearances to an asset catalog and define the token from it. Never carry meaning by color alone: `Badge` pairs its colored dot with a title.

## Typography

Dynamic Type text styles are the type scale: `.largeTitle`, `.title`, `.title2`, `.title3`, `.headline`, `.body`, `.callout`, `.subheadline`, `.footnote`, `.caption`, and `.caption2`. They scale with the person's text size, so the policy check rejects fixed font sizes outside DesignSystem.

Use the smallest useful subset, and give peers the same style. The demo uses navigation titles for screens, `.headline` for row titles, `.subheadline` for row metadata, and `Badge`'s `.caption` for labels. Add weight with `.fontWeight(.medium)` or `.fontWeight(.semibold)` only when it helps scanning. `.headline` is already semibold.

Font roles choose the design:

| Role | Design | Use it for |
| --- | --- | --- |
| `Typography.interface` | SF Pro | controls, labels, and most text |
| `Typography.editorial` | New York | long-form reading |
| `Typography.data` | SF Mono | codes, identifiers, and fixed-width values |

Apply a role with `.fontDesign(Typography.editorial)`. For numbers that update or line up in columns, keep the role and add `.monospacedDigit()`.

San Francisco and New York adjust their tracking to each size, so don't set `.tracking` or `.kerning` on system text. Let text wrap. Don't limit lines on text that grows with Dynamic Type unless truncation is part of the design, and don't add manual line breaks to fix one width.

A custom font belongs in DesignSystem as `Font.custom(_:size:relativeTo:)`, so it scales with the text style it replaces. Register its files under `UIAppFonts` in the app's Info.plist in `Project.swift`, and keep its license beside the files.

## Spacing and size

`Spacing` runs from `xxSmall` to `xxLarge`. Use it for padding, stack and grid spacing, and `Spacer(minLength:)`. Keep related items close, from `xSmall` to `small`, separate groups with `medium` to `large`, and separate sections with `xLarge` or more. Prefer the system's own spacing where it exists: `.padding()` with no value, and the insets of `List` and `Form`.

A dimension that should grow with text, such as an icon beside a label, uses `@ScaledMetric(relativeTo:)` seeded from a token. `Badge` sizes its dot this way.

Frame sizes, aspect ratios, and grid columns are structure, so they stay as values in the view. Keep every hit area at least 44 by 44 points.

## Shapes and radius

Use `Radius.small`, `Radius.medium`, and `Radius.large` for the corners of custom surfaces. `RoundedRectangle` draws continuous corners by default.

Inside a container that has its own corners, such as a sheet, a card, or the display, use `ConcentricRectangle()` so the corner follows its container. Set a container's shape for its children with `.containerShape(_:)`. Use `Capsule()` for pills, as `Badge` does, and `Rectangle()` for square corners.

## Strokes and separators

Separate rows and groups with `Divider()` or the separators `List` draws. They draw a hairline at the display's scale.

Outline a custom shape with `.strokeBorder(_:lineWidth:)` and a `Stroke` token. `strokeBorder` draws inside the frame, so an outline never changes the layout. Don't draw your own focus ring: the system draws focus for keyboards and Full Keyboard Access.

## Depth

The theme has no shadow tokens. Depth comes from the system:

- Navigation bars, toolbars, tab bars, sheets, and menus use Liquid Glass automatically.
- Custom floating controls use `.glassEffect()`, and buttons can use `.buttonStyle(.glass)` or `.buttonStyle(.glassProminent)`. Group nearby glass in a `GlassEffectContainer` so the shapes blend.
- Content surfaces use materials, such as `.background(.regularMaterial, in: .rect(cornerRadius: Radius.large))`, or a fill tier.

Glass belongs to the navigation layer above content. Don't put it on content itself, and don't stack glass on glass. A custom shadow is a theme gap: report it.

## Icons

Use SF Symbols, through `Image(systemName:)`, `Label`, or `Button(_:systemImage:action:)`. Symbols scale with the font around them and take its weight, so size them with a text style, not a frame. Choose a rendering mode with `.symbolRenderingMode(_:)` when one color isn't enough.

Every icon-only control still has a title. VoiceOver reads it, and iPhone Duo's vertical toolbars can show it. Hide decorative images with `.accessibilityHidden(true)`. Export a custom symbol from the SF Symbols app as a template and add it to an asset catalog.

## Motion

Use `Motion.small` for controls, toggles, selection, and small popovers, and `Motion.large` for panels, expanding sections, and layout changes. Navigation pushes, sheets, and other system transitions bring their own motion. Don't animate them by hand.

When `@Environment(\.accessibilityReduceMotion)` is true, replace movement with a cross-fade, or with no animation. Give feedback for state a person changed with `.sensoryFeedback(_:trigger:)`, as the favorite button does.

## States

Disabled, loading, empty, and failed are different states:

- Disable a control with `.disabled(_:)`. Don't fade it to fake the state.
- Show work in progress with `ProgressView`.
- Show an empty or failed screen with `ContentUnavailableView`: what's missing, plus the next action when there is one.
- Show selection with the system's selection styles, and never with color alone.
