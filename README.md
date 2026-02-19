# Decision Fatigue Killer

A SwiftUI + SwiftData iOS App to reduce decision fatigue by providing stable daily picks for Meals, Outfits, and Workouts.

## Setup Instructions

1.  **Open in Xcode**: Open the folder containing these files in Xcode 15+ (iOS 17 target).
2.  **Add Files**: Ensure all files in `Data`, `Domain`, and `UI` are added to the target.
3.  **Build & Run**: Select an iOS Simulator (iPhone 15/16) and press Cmd+R.

## No-Mac Workflow (CI/CD)

This project is configured for development on non-macOS environments using **XcodeGen** and **GitHub Actions**.

### CI Pipeline
- **Generation**: The Xcode project (`.xcodeproj`) is not committed. It is generated on the fly by CI using `project.yml`.
- **Trigger**: Pushing to `main` or opening a Pull Request automatically triggers the build.
- **Results**: Check the **Actions** tab in GitHub. If tests fail, download the `TestResults` artifact to inspect failures.

### Local Testing (Windows)
To run the pure logic tests on Windows (requires Swift Toolchain):
1.  Navigate to the package directory: `cd Packages/DecisionPicker`
2.  Run tests: `swift test`
This validates the core decision algorithm without needing an iOS Simulator.

## Architecture

-   **Data**: `Models.swift` containing `Category`, `OptionItem`, `PickHistory`, `Settings`. `DataController.swift` handles seeding.
-   **Domain**: `PickService.swift` containing application logic using `DecisionPicker` (pure logic) and SwiftData.
-   **UI**: SwiftUI views separated by feature (`TodayView`, `OptionsView`, `SettingsView`).
-   **Tests**: `Tests/ModelTests.swift` and `Tests/DecisionPickerTests.swift`.

## Features

-   **Today**: View daily picks. They persist for the day unless re-rolled.
-   **Options**: Add your own options (e.g., "Pizza", "Salad", "Gym", "Run"). Delete or disable them.
-   **Settings**: Configure "No Repeat Days" (default 3) per category. Reset history.
