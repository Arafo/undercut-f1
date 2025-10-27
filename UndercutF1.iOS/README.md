# UndercutF1 iOS UI Prototype

This SwiftUI prototype recreates the core visual language of the UndercutF1 timing client for an iOS experience. The package uses static mock data so you can explore the layout without connecting to the live timing back end.

## Features

- **Timing Tower** with sector splits, tyre compounds, lap metrics, and relative gaps.
- **Race Control** feed highlighting investigations, penalties, and weather alerts.
- **Strategy Board** showing stint timelines and pit stop information.
- **Driver Tracker** with a stylised circuit map and relative gap cards for a selected driver.

## Running the App

1. Open the `UndercutF1.iOS/Package.swift` file in Xcode 15 or later.
2. Select the `UndercutF1 iOS` scheme and choose an iOS 17 simulator or device.
3. Build and run the app to explore the mocked session UI.

> **Note**
> This prototype focuses on the interface and does not include networking or authentication. Hook it up to the `UndercutF1.Data` library to drive the UI with live timing data.
