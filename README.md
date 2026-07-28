# TrafficVienna

TrafficVienna is a native SwiftUI companion for Vienna public transport. It
combines nearby live departures, station search, a focused map, official service
alerts, favourites, widgets, and Live Activities in one privacy-conscious app.

## Product highlights

- Nearby departures with explicit location, offline, stale-data, and failure states
- Fast diacritic-insensitive station search and recent stops
- Tappable, spatially thinned station map with Vienna-centre fallback
- Service, accessibility, and stop-change alerts with filtering and search
- Favourite stations and routes shared with Home Screen and Lock Screen widgets
- Minute-accurate widget countdowns with a five-minute network refresh cadence
- App Shortcuts for nearby departures, search, and favourites
- Dynamic Island and Lock Screen Live Activities for a selected departure
- English and German localisation, Dynamic Type, VoiceOver labels, and Reduce Motion

## Requirements

- Xcode 26
- iOS 26 simulator or device

## Build and test

```sh
xcodebuild \
  -scheme TrafficVienna \
  -project TrafficVienna.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build

xcodebuild \
  -scheme TrafficVienna \
  -project TrafficVienna.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  test
```

The app reads the bundled Wiener Linien station catalogue and fetches live
departure and disruption data from the official Wiener Linien realtime API.
Location remains in memory and anonymous use does not require an account.
