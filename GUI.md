# GUI: the Saddle design language

This guide and the files in `gui/` define how the app looks and how to build interface with it. DesignSystem owns the theme: the tokens in `Packages/UI/Sources/DesignSystem/Tokens/` and the shared components beside them. Screens refer to tokens by name and never restate their values.

## The theme

| Family | Use it for | Example |
| --- | --- | --- |
| `Spacing` | padding, stack and grid spacing, and spacer lengths, on a scale from `xxSmall` to `xxLarge` | `.padding(Spacing.medium)` |
| `Radius` | corner radii of custom surfaces: `small`, `medium`, `large` | `RoundedRectangle(cornerRadius: Radius.medium)` |
| `Stroke` | outline widths: `small`, `medium`, `large` | `.strokeBorder(.separator, lineWidth: Stroke.small)` |
| `Palette` | colors the system doesn't choose for you: secondary text, favorites, and status | `.foregroundStyle(Palette.secondaryText)` |
| `Typography` | font roles: `interface`, `editorial` for long reading, and `data` for codes | `.fontDesign(Typography.editorial)` |
| `Motion` | animation curves: `small` for controls, `large` for panels and layout | `.animation(Motion.small, value: isOn)` |

Type sizes are Dynamic Type text styles such as `.headline` and `.body`, not tokens. Depth comes from Liquid Glass and materials, so the theme has no shadow tokens. The [theme reference](gui/theme.md) lists every token and its value. `mise run gui` regenerates it from the Swift files, and `mise run check` fails while it's stale.

## Rules for UI work

Follow this guide whenever you create or edit an interface, even when the request doesn't mention design. A new screen uses the existing design system by default.

- **Look before you style.** Find the nearest screen that does something similar, the components it uses, and the tokens they reference. Match them.
- **Let the system choose first.** SwiftUI's controls, text styles, and semantic colors such as `.primary`, `.tint`, and `.fill.tertiary` already adapt to Dark Mode, Dynamic Type, Increase Contrast, Liquid Glass, and every display size. Reach for a token when the system leaves a choice to you.
- **Name values at use sites.** Literal values belong only in token definitions. Outside DesignSystem, the policy check rejects raw colors, named hues such as `.yellow`, font sizes, numeric spacing and radii, stroke widths, line spacing, tracking, and animation timings. Zero is allowed.
- **Report a missing token.** If no token fits, say so in your summary and continue with the rest of the work. Don't approximate with a nearby token, add arithmetic such as `Spacing.small + 2`, or hide a literal in a local constant. See the [theme contract](gui/theme-contract.md).
- **Change the theme deliberately.** A token change reaches every screen that uses it. Make one only when asked, and say which screens it affects.
- **Keep layout decisions in the layout.** Frame sizes, aspect ratios, grid columns, and layout priorities describe structure, not the theme, so they stay in the view.
- **Bias toward minimalism.** Give a screen a useful title, its content, and the actions people need. Omit eyebrows, filler subtitles, slogans, and explanations of the obvious. See [Interface judgment](gui/interface-judgment.md).
- **Keep accessibility intact.** Every control has a label, text scales with Dynamic Type, hit areas are at least 44 by 44 points, and movement respects Reduce Motion. The audits in `App/UITests/` check contrast, hit areas, labels, and the largest text size.

## Read what the task needs

A small edit needs only the section it touches.

| Need | Reference |
| --- | --- |
| Color, type, spacing, shapes, strokes, depth, icons, motion, and states | [Foundations](gui/foundations.md) |
| Who owns a value, using and adding tokens, and changing the theme | [Theme contract](gui/theme-contract.md) |
| Titles, copy, empty states, hierarchy, and removing what adds nothing | [Interface judgment](gui/interface-judgment.md) |
| Choosing system controls, using DesignSystem components, and building new ones | [Components](gui/components.md) |
| Checking appearance, modes, text sizes, iPhone Duo, and common failures | [Verification](gui/verification.md) |
| Every token and its current value | [Theme reference](gui/theme.md) |
