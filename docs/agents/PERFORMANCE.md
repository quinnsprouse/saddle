# Performance

Measure Release builds. Debug numbers, and numbers taken while something else builds, are not evidence.

## Measure

| Command | Use |
| --- | --- |
| `mise run perf` | Run `App/PerformanceTests` in Release on the pinned simulator and write `.scratch/perf/latest.json` |
| `mise run perf -- --save NAME` | Also save the report as the baseline `.scratch/perf/NAME.json` |
| `mise run perf -- --compare NAME` | Measure now and fail on a regression against that baseline |
| `mise run perf -- --device UDID --team TEAM_ID` | Measure on a connected iPhone, signed with your team |

Each report records the commit, whether the tree was dirty, the Mac, macOS, Xcode, the destination, and every sample. A comparison is refused unless the Mac, macOS, the Xcode version and build, the destination and its OS build, the physical device, and the report schema all match.

A metric regresses when its median moves in its worse direction by more than `max(relative × baseline, floor)`, using the tolerances in `performance.json`. XCTest marks each metric as preferring smaller or larger values. A metric with neither is reported as `info` and never fails. The floors keep timer jitter from reading as a regression. Never raise a tolerance to pass a change.

The simulator runs on the Mac's CPU, so its numbers show relative changes on one machine, not what a person feels. On a device, the scroll test also reports hitch time ratios. Make decisions about feel on the oldest iPhone you support. CI never gates on wall-clock time.

## What the suite covers

- **Launch:** `XCTApplicationLaunchMetric` to a responsive first frame, with isolated storage.
- **Scroll:** `scrollDecelerationMetric` for a fast fling through 10,000 rows.
- **Search:** the `search` signpost interval in `LibraryModel`, while typing a query.

Add a measurement for each path a person would notice getting slower. Wrap app work in an `OSSignposter` interval, as `LibrarySignposts` does, and measure it with `XCTOSSignpostMetric`.

## Change something that might be slower

1. Save a baseline from the old code: `mise run perf -- --save before`.
2. Make one change, then compare: `mise run perf -- --compare before`.
3. Compare the old code with itself first if you need to know the noise on your Mac.
4. One regressed run is a lead, not a verdict. Repeat it, then profile.

## Profile

- Record with Instruments from the command line, then open the trace in Instruments: `xcrun xctrace record --template 'Time Profiler' --device <UDID> --time-limit 10s --output .scratch/traces/launch.trace --launch -- <path to .app>`. Everything after `--launch --` goes to the app, so it comes last. Swap in `Animation Hitches`, `Allocations`, `Leaks`, or `SwiftUI`.
- MetricKit payloads from people's devices arrive in `MetricsObserver`. Forward them to your analytics before you ship.

## Rules

- Keep the main actor for UI. Decoding, search, sorting, and file work run in `@concurrent` functions or actors, check cancellation, and reject stale results.
- Bound caches, queues, and histories. Replace obsolete work instead of queueing it.
- Prefer `List` and lazy stacks, stable identity, and small concrete row views. Pass rows values.
- Measure every new dependency's launch-time and size cost before you keep it.
