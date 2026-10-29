# Verification

How to check interface work, and what to look at first when it goes wrong. Read [GUI.md](../GUI.md) first.

## What each check proves

| Check | Proves | Doesn't prove |
| --- | --- | --- |
| `mise run check` | the code uses tokens, compiles, and the theme reference is current | how the screen looks |
| journeys in `App/UITests/` | the behavior a person sees, on the pinned simulator | the screen's visual quality |
| `AccessibilityAuditTests` | contrast, hit areas, labels, and the largest text size, on the audited screens | screens without an audit |
| a screenshot | how one state looks at one size | other states, sizes, and appearances |

Report these separately. Source inspection never establishes rendered contrast or visual quality. Add an audit to `AccessibilityAuditTests.swift` for each new screen.

## Look at the result

Run `mise run dev -- --screenshot .scratch/screen.png` and open the screenshot. Then check the appearances and sizes the change could affect, on the booted simulator:

| Check | Command | Reset |
| --- | --- | --- |
| Dark appearance | `xcrun simctl ui booted appearance dark` | `appearance light` |
| Increase Contrast | `xcrun simctl ui booted increase_contrast enabled` | `increase_contrast disabled` |
| Largest text size | `xcrun simctl ui booted content_size accessibility-extra-extra-extra-large` | `content_size large` |

The pinned simulator is iPhone Duo, which boots on its outer display. Check the inner display and folding by hand in Device Hub: run `mise run dev -- --open`, then open, fold, and rotate the device while the app runs. See [SwiftUI](../docs/agents/SWIFTUI.md#adaptive-layout-and-iphone-duo).

## Symptoms

| Symptom | Look first at |
| --- | --- |
| The policy check reports `design-token` | the literal at that line: replace it with a token from the [theme reference](theme.md), or report a missing token |
| `check` reports that `gui/theme.md` is stale | a token changed without `mise run gui` |
| The audit reports low contrast on secondary text | `.secondary` used where `Palette.secondaryText` belongs |
| Text truncates at large sizes | a `lineLimit`, a fixed frame height, or an `HStack` that needs `ViewThatFits` |
| Content sits under a bar | a background or frame that ignores the safe area |
| Content sits on iPhone Duo's fold | custom layout that spans the inner display: use a split container, or avoid `reservedRegions(kind: .division)` |
| A layout looks right on iPhone but stretched on iPad or the inner display | a phone layout without size classes or an adaptive container |
| Glass looks muddy | glass stacked on glass, or glass applied to content instead of controls |
| A control works with touch but not VoiceOver | a missing label, or an element hidden that shouldn't be |
| A journey can't find the search field on iPhone Duo | search collapsed into a toolbar button: use `openSearch()` from `App/TestSupport/` |
