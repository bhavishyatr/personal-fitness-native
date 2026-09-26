# Personal Fitness Native

A native iOS fitness app built with SwiftUI and HealthKit.

## Milestone 1

The first screen displays:

- today's date
- today's step count from Apple Health
- progress toward a 10,000-step daily goal
- pull-to-refresh

If HealthKit has no step samples, the app still renders and displays `0` steps.

## Stack

- Swift
- SwiftUI
- Observation (`@Observable`)
- Swift Concurrency
- HealthKit
- XcodeGen
- GitHub Actions using the `xcode-27` runner

## Browser-only development workflow

1. Work on source code in GitHub / with an AI coding assistant.
2. Push to `main` or open a pull request.
3. GitHub Actions generates the Xcode project.
4. CI builds the native app for an iPhone Simulator.
5. CI boots an iPhone Simulator, launches the app, and captures a screenshot.
6. Open the workflow run in GitHub and download the `iphone-render` artifact to see the rendered app entirely from your browser.
7. Use a browser-accessible cloud Mac only when interactive simulator debugging is needed.
8. On a real iPhone, grant Apple Health read access to see real step data.

The CI screenshot uses a launch-only sample step count so the HealthKit permission sheet does not block the automated render. Normal app launches always use HealthKit.

## Generate the project on a Mac

```bash
brew install xcodegen
xcodegen generate
open PersonalFitnessNative.xcodeproj
```

Select an iPhone simulator and Run.
