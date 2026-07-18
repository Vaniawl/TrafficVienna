# TrafficVienna

SwiftUI iOS app for live Vienna public transport departures.

## Current capabilities

- Neobank-style smart dashboard with nearby live departures.
- Station search, map, favourites, personalised service alerts, and commute routines.
- Device-local email authentication and native Sign in with Apple.
- Departure reminders, Live Activities, Dynamic Island, and a home-screen widget.
- Indexed station search/spatial queries, throttled API access, active-tab polling, and stale offline fallback.

## Validation

```sh
xcodebuild -scheme TrafficVienna -project TrafficVienna.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' test
```

The shared scheme includes the application, widget extension, and `TrafficViennaTests` unit/performance target.

## Distribution limitations

- Email accounts are local to one device; password recovery and cross-device sync require a backend.
- Sign in with Apple must be enabled for the production App ID in Apple Developer.
- The `trafficvienna://` URL scheme is registered and routed in-app; universal links still require an Associated Domains deployment configuration.
- Full A→B route planning needs a verified GTFS/routing source and is not implemented by the departure-monitor API alone.
