# TrafficVienna

SwiftUI iOS app for live Vienna public transport departures.

## Current capabilities

- Neobank-style smart dashboard with nearby live departures.
- Station search, map, favourites, personalised service alerts, and commute routines.
- Device-local email authentication and native Sign in with Apple.
- Optional device-owner app lock with an immediate privacy shield and configurable unlock timeout.
- User-controlled JSON backup and confirmed restore of local profile preferences and travel data.
- Departure reminders, Live Activities, Dynamic Island, and a home-screen widget.
- Indexed station search/spatial queries, throttled API access, active-tab polling, and stale offline fallback.
- App and widget privacy manifests with declared UserDefaults reasons and no tracking/data-collection declaration.
- Validated English, German, and Ukrainian App Store metadata plus review and screenshot guidance in [`docs/app-store/`](docs/app-store/).

## Validation

```sh
xcodebuild -scheme TrafficVienna -project TrafficVienna.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' test
```

The shared scheme includes the application, widget extension, `TrafficViennaTests` unit/performance target, and `TrafficViennaUITests` smoke target. UI coverage verifies email registration, validation messaging, and primary tab navigation with an isolated DEBUG-only test store.

## Distribution limitations

- Email accounts are local to one device; password recovery and cross-device sync require a backend.
- Sign in with Apple must be enabled for the production App ID in Apple Developer.
- The `trafficvienna://` URL scheme is registered and routed in-app; universal links still require an Associated Domains deployment configuration.
- Full A→B route planning needs a verified GTFS/routing source and is not implemented by the departure-monitor API alone.
- App Store submission still requires publishing the [privacy policy](docs/PRIVACY.md) at a public URL.
