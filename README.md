# Personal Fitness Native

A SwiftUI and HealthKit performance history hub. Review recorded activity, personal records, and changes over time, grouped by workout type. The app does not prescribe training plans or coaching.

## Performance dashboards

- **Overview:** activity totals, workout dashboard directory, recent sessions.
- **Running:** longest distance/duration, climbing when recorded, best whole runs near 1–4 miles, and separate fastest continuous 1–4 mile efforts.
- **Strength:** session frequency, duration and weekly activity. Exercise-level weights, reps, sets and equipment are not supplied by the current import; lifting records are withheld rather than inferred.
- **History:** searchable sessions with date, source, environment and relevant measurements.
- Walking, hiking, cycling, swimming, rowing, yoga, Pilates, HIIT, badminton and other activity dashboards are available through Overview. Distance appears only for distance-based activities.
- Dashboard period filters: last 30 days, last 365 days, all time, custom date ranges. Weekly duration and distance charts, previous-30-day session comparisons, and side-by-side comparison of sessions with matching workout type and environment. Records open calculation details and the source workout.
- Indoor, outdoor and unspecified-environment records are calculated separately. Records are best *accessible recorded* performances, not certified race results.

## Running record definitions

Whole-run records use active workout duration for complete runs within ±0.15 mile of the target. Actual distance is shown in session details. These approximate-distance runs are not exact mile records.

Continuous efforts use workout-associated distance samples and linear interpolation, considering both start and end sample boundaries. They use elapsed time including pauses. Results are labeled estimates. Samples with invalid values, overlaps, intervals or gaps above 30 seconds, or totals differing from the workout distance by more than 2% are excluded. Partial data is never extrapolated or scaled to fill the workout. Denied access and absent samples can both yield no records.

## Browser-only development

1. Edit Swift source in GitHub and open a PR targeting `main`, or push to `main`.
2. **Actions → iOS Build and Render → Run workflow** also starts a manual run.
3. CI runs analytics checks, generates the Xcode project with XcodeGen, and builds on `xcode-27` with Swift 6.
4. CI boots an iPhone Simulator and captures Overview, Running, Strength and History.
5. Open the completed run and download **Artifacts → iphone-render**. It contains four PNG files, retained for 30 days. Re-run if an artifact has expired.

`--ui-snapshot` uses sample data and skips HealthKit permission prompts. `--snapshot-running`, `--snapshot-strength` and `--snapshot-history` choose the launch tab; default is Overview. Normal launches read Apple Health on device. Screenshots are render smoke checks, not assertions about every UI interaction.

## Local development

```bash
brew install xcodegen
xcodegen generate
open PersonalFitnessNative.xcodeproj
```

Select an iPhone simulator and run. A physical iPhone with Health permissions is required to validate real workout import.

Run the standalone calculation checks on a Mac:

```bash
swiftc PersonalFitnessNative/Features/Performance/PerformanceModels.swift Tests/PerformanceMathTests.swift -o /tmp/performance-tests
/tmp/performance-tests
```

## Current data limits

Strength exercise logs, swimming stroke/pool classification, cycling power/cadence, rowing splits, routes, and heart-rate series are not imported. Relevant dashboards explicitly state these limits. Swimming speed records are withheld until comparable stroke and pool context is available. HealthKit stays on device; no backend is used. No cross-source duplicate detection is currently performed.
