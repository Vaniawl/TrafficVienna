# TrafficVienna

TrafficVienna is a native SwiftUI companion for Vienna public transport. It
combines nearby live departures, station search, a focused map, official service
alerts, favourites, widgets, and Live Activities in one privacy-conscious app.

## Product highlights

- Nearby departures with explicit location, offline, stale-data, and failure states
- Fast diacritic-insensitive station search and recent stops
- Tappable, spatially thinned station map with camera-aware area search
- Service, accessibility, and stop-change alerts with filtering and search
- Favourite routes shared with Home/Lock Screen widgets that open in Favourites
- Minute-accurate widget countdowns with a five-minute network refresh cadence
- App Shortcuts for nearby departures, search, and favourites
- Dynamic Island and Lock Screen Live Activities for a selected departure
- English and German localisation, Dynamic Type, VoiceOver labels, and Reduce Motion

## Requirements

- Xcode 26
- iOS 26.0 simulator or device

## Build and test

```sh
bash scripts/build.sh
bash scripts/test.sh
```

The scripts validate repository/OpenCode contracts and resolve an exact available
`iPhone 17` UUID, avoiding ambiguous name-only destinations.

The app reads the bundled Wiener Linien station catalogue and fetches live
departure and disruption data from the official Wiener Linien realtime API.
Location remains in memory and the app does not require an account. See the
[privacy policy](PRIVACY.md), [App Store readiness evidence](docs/release/app-store-readiness.md),
and [TestFlight smoke checklist](docs/release/testflight-smoke-checklist.md).
