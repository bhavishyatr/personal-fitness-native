# AI Development Guide

## Product direction
Personal Fitness Native is a native iOS fitness app. Keep the product Apple-first and Swift-first.

## Technical rules
- Use Swift and SwiftUI for UI and application code.
- Prefer Apple frameworks over third-party packages.
- Use Swift concurrency (`async`/`await`) for asynchronous work.
- Use Observation (`@Observable`) for feature state where appropriate.
- Keep HealthKit access behind a small service boundary.
- Keep features modular under `PersonalFitnessNative/Features`.
- Do not add React Native, Expo, Ionic, Capacitor, Flutter, or .NET MAUI.
- Do not add a backend until a concrete feature requires one.
- New code should compile under Swift 6 strict concurrency.
- Preserve accessibility labels for primary metrics and controls.

## Current milestone
Render the first iPhone app and show the current day's step total from HealthKit.
