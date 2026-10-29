# Theme contract

Who owns each value, and how the theme changes. Read [GUI.md](../GUI.md) first.

## Define the theme once

The theme lives in `Packages/UI/Sources/DesignSystem/Tokens/`, one enum per family, with one `public static let` per token. These files and the DesignSystem components beside them are the only Swift code that holds literal style values. The `design-token` allowance in `policy.json` covers exactly that directory, and the policy check rejects literals everywhere else.

`gui/theme.md` is generated from the token files. Never edit it. Change a token, run `mise run gui`, and commit both. `mise run check` fails while the reference is stale.

Name a token by its place on a scale, such as `Spacing.xSmall` or `Radius.large`, or by its role when the value carries app meaning, such as `Palette.favorite`. A role name says why the value exists, so prefer it for colors.

## Use only existing tokens

Ordinary UI work uses the existing tokens, the system's semantic styles, and Dynamic Type text styles. To get a value the theme doesn't have, don't:

- invent a token or a local constant, such as `private let cardPadding = 14`
- do arithmetic on tokens, such as `Spacing.small + 2`
- borrow a token for a different role because its value happens to match

A missing token is a theme gap. Name the gap in your summary, use the nearest existing component or token only if its role truly fits, and continue with the rest of the work. Adding the token is a separate decision.

Structure isn't theme. Frame sizes, aspect ratios, grid columns, minimum hit areas, and layout priorities stay in the view as values.

## Change the theme deliberately

A token change reaches every screen that uses it. Make one only when the request is for a theme change, and before you change it, find its consumers:

```sh
grep -rn "Spacing.medium" Packages App
```

Edit the definition in `Tokens/`, run `mise run gui`, and say which screens change. Don't add a parallel scale to avoid touching a shared token.

To add a token, add a `public static let` to the right family file and keep the scale in order. Periphery retains the `Tokens/` files, so a scale can be complete before every step has a consumer. Add a family as a new file in `Tokens/`. The generator picks it up.

To remove a token, delete its consumers first, then the definition.

## Components own their assignments

A DesignSystem component decides which tokens its parts use. `Badge` picks its dot size, spacing, padding, fill, and type. Screens pass content and meaning, such as a title and a `Tone`, and never styles. To change how every badge looks, change `Badge` once.

When two features need the same composition, move it into DesignSystem as a component instead of copying its styling.
