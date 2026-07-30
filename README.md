# TrafficVienna

TrafficVienna is a native SwiftUI companion for Vienna public transport. Its
four journey-focused areas combine nearby live departures, station and map
discovery, personalised official service alerts, saved journeys, widgets, and
Live Activities in one privacy-conscious app.

## Product highlights

- A Home dashboard for the next saved departure, relevant service status, saved
  stops, and nearby departures
- Fast diacritic-insensitive station search, recent stops, and a focused map
  combined in Discover
- Tappable, spatially thinned station map with camera-aware area search and a
  Vienna recovery action
- Personalised service, accessibility, and stop-change alerts with filtering and
  search
- Saved stations and routes shared with Home/Lock Screen widgets that open Saved
- Minute-accurate widget countdowns with a five-minute network refresh cadence
- App Shortcuts for nearby departures, search, and favourites
- Dynamic Island and Lock Screen Live Activities for a selected departure
- English and German localisation, Dynamic Type, VoiceOver labels, and Reduce Motion
- Unit, model, and end-to-end UI regression coverage

## Requirements

- Xcode 26
- iOS 26.0 simulator or device

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
Location remains in memory and the app does not require an account. See the
[privacy policy](PRIVACY.md), [App Store readiness evidence](docs/release/app-store-readiness.md),
and [TestFlight smoke checklist](docs/release/testflight-smoke-checklist.md).
