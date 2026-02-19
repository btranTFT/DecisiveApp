# Decision Fatigue Killer

A SwiftUI + SwiftData iOS App to reduce decision fatigue by providing stable daily picks for Meals, Outfits, and Workouts.

## Setup Instructions

1.  **Open in Xcode**: Open the folder containing these files in Xcode 15+ (iOS 17 target).
2.  **Add Files**: Ensure all files in `Data`, `Domain`, and `UI` are added to the target.
3.  **Build & Run**: Select an iOS Simulator (iPhone 15/16) and press Cmd+R.

## Architecture

-   **Data**: `Models.swift` containing `Category`, `OptionItem`, `PickHistory`, `Settings`. `DataController.swift` handles seeding.
-   **Domain**: `PickService.swift` containing application logic using `DecisionPicker` (pure logic) and SwiftData.
-   **UI**: SwiftUI views separated by feature (`TodayView`, `OptionsView`, `SettingsView`).
-   **Tests**: `Tests/ModelTests.swift` and `Tests/DecisionPickerTests.swift`.

## Features

-   **Today**: View daily picks. They persist for the day unless re-rolled.
-   **Options**: Add your own options (e.g., "Pizza", "Salad", "Gym", "Run"). Delete or disable them.
-   **Settings**: Configure "No Repeat Days" (default 3) per category. Reset history.
