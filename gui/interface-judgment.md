# Interface judgment

Bias toward minimalism. Build the smallest complete interface that serves the task: a useful title, the content, and the actions people need. Every visible element should add information, enable an action, or give context the person needs. Correct tokens alone don't make a clear interface. Read [GUI.md](../GUI.md) first.

## Start with what the platform provides

Before you add anything to a screen, look at what the system already gives it: the navigation title, the back button, the toolbar, the search field, and the split view's sidebar. A navigation title is a sufficient header. Don't add a second title inside the content, a custom back row, or a header that repeats the toolbar.

A specific title can stand alone. Add metadata only when it helps people understand or act on the content, and only from data the app actually has. Don't pair a title with a subtitle, a category label, or a badge by default.

## Keep copy useful

Omit eyebrows (small labels above headings), taglines, motivational empty-state prose, and decorative badges. Add supporting copy only when it gives context that the title, content, and controls don't already give. Don't narrate the workflow or the implementation, such as "Saved on this device". Mention a technical limit only at the decision it affects, and only when it has a consequence for the person.

Keep empty and failed states brief. `ContentUnavailableView` names what's missing and offers the next useful action. Don't surround that action with a slogan or a restatement of the screen's title.

## Give each fact one home

Each fact gets one primary place: the row, the detail screen, a chart, or a summary. Don't repeat the same value in a row, its badge, and its detail header at equal emphasis. In the demo, a trail's distance appears in its row's metadata and once on its detail screen, as a `LabeledContent` value.

Label charts and values with their units. If several values share a period or a unit, state it once at their common scope.

## Reuse a small visual vocabulary

Choose the fewest text styles, weights, and colors that explain the hierarchy. A new section doesn't need a new style. Give peer rows and peer headings the same style. Use spacing and grouping before you add another font size, weight, color, fill, or divider.

Use regular text by default. Emphasize a phrase only when it materially helps scanning. Don't bold a number just because it's a number.

## Make widths and alignment deliberate

On a wide window, such as an iPad or iPhone Duo's inner display, don't let prose run the full width. Keep reading text in a comfortable column and align related content to the same leading edge. Prefer containers that adapt, such as `NavigationSplitView`, to stretching a phone layout.

## Keep cues consistent with behavior

Show read-only values as values: `LabeledContent`, metadata text, or a badge. Don't give a static value a button's look, a chevron, or a tap target. Give equivalent controls the same look and behavior, and add an interaction only when it does something real.

## Finish by removing what adds nothing

Review the normal state, the empty state, and the failed state. For each subtitle, badge, caption, explanation, and divider, name the information or action it adds, and remove it if there is none. Keep the requested content, labels that VoiceOver needs, and cues people need to act. A title with no supporting copy is a complete design.
