# TrafficVienna

SwiftUI iOS app for live Vienna public transport departures.

## Current capabilities

- Neobank-style smart dashboard with nearby live departures.
- Station search, an adaptive low-clutter map, favourites, personalised service alerts, and commute routines.
- Actionable first-run and empty states, native iOS 26 Liquid Glass controls, responsive tab-bar minimisation, motion that respects accessibility settings, and direct Apple Maps transit/walking directions.
- Responsive device-local email authentication with repeated-attempt cooldown and native Sign in with Apple.
- Optional device-owner app lock with an immediate privacy shield and configurable unlock timeout.
- User-controlled JSON backup and confirmed restore of local profile preferences and travel data.
- Departure reminders, Live Activities, Dynamic Island, and Home/Lock Screen widgets in small, medium, large, circular, rectangular, and inline families.
- Widget countdowns advance between five-minute network refreshes from each row's actual fetch time; favourite-route synchronization remains immediate and refresh work remains deduplicated and staggered.
- Indexed station search/spatial queries, off-main batch response processing, throttled API access, bounded and memory-pressure-aware response caching, active-tab polling, Low Data/Low Power/thermal-aware cadence and continuous animations, and stale offline fallback.
- App and widget privacy manifests with declared UserDefaults reasons and no tracking/data-collection declaration.
- English, German, and Ukrainian app and widget interfaces, including localized dynamic countdown and freshness text.
- Validated English, German, and Ukrainian App Store metadata plus review and screenshot guidance in [`docs/app-store/`](docs/app-store/).

## Validation

```sh
xcodebuild -scheme TrafficVienna -project TrafficVienna.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' test
```

The shared scheme includes the application, widget extension, `TrafficViennaTests` unit/performance target, and `TrafficViennaUITests` smoke target. UI coverage verifies email registration, validation messaging, primary tab navigation, appearance and account flows, station directions, and favourite station/route flows with isolated DEBUG-only state and network fixtures.

### Personal Team device builds

The Debug configuration uses development-only bundle identifiers and empty entitlement files so the app can be installed with a free Apple Personal Team. Select your Personal Team for both the `TrafficVienna` and `TrafficViennaWidgetExtension` targets, choose the connected iPhone, and run the shared scheme. Email authentication and the main app remain available; Sign in with Apple and cross-process App Group widget synchronization require a paid Apple Developer team and are intentionally available only in the Release configuration. Release retains the production bundle identifiers and full entitlement files.

## Distribution limitations

- Email accounts are local to one device; password recovery and cross-device sync require a backend.
- Sign in with Apple must be enabled for the production App ID in Apple Developer.
- The `trafficvienna://` URL scheme is registered and routed in-app; universal links still require an Associated Domains deployment configuration.
- Full in-app A→B route planning needs a verified GTFS/routing source and is not implemented by the departure-monitor API alone; station screens hand transit and walking directions to Apple Maps.
- App Store submission still requires publishing the [privacy policy](docs/PRIVACY.md) at a public URL.
