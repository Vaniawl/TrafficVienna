# TrafficVienna — Context

## What we're building

A SwiftUI iOS app for live Wiener Linien (Vienna public transport) departures. The app shows nearby stops, lets users search for any station, view live departure boards grouped by platform, save favourite stations and line/direction pairs, browse network-wide service alerts, explore stations on an adaptive map, hand transit or walking directions to Apple Maps, and track a selected departure on the Lock Screen via Live Activities. Home and Lock Screen widgets show the user's priority favourite routes.

The app also has a device-local authentication gate, a neobank-style dashboard, actionable first-run and zero-data states, native iOS 26 Liquid Glass navigation/control surfaces, commute routines, personalised disruption priority, departure reminders, offline stale-response fallback, and tested deep-link routing foundations.

### Architecture

- **5 direct tabs** (RootTabView): Nearby, Search, Map, Alerts, Favourites; the native tab bar minimises while scrolling
- **MVVM** — views are dumb, state lives in ViewModels via `@Published`
- **Key ViewModels**: StationDetailViewModel, NearbyViewModel, DisruptionsViewModel, FavoritesListViewModel
- **Services**: MonitorService (actor, centralises API calls with caching + coalescing + throttling + rate-limit backoff), NetworkManager (protocol-based), LocationManager (CLLocationManager wrapper)
- **Storage**: UserDefaults-based repositories for favourites (FavoriteRoute, FavoriteStation), RecentSearchesStore
- **Authentication**: `AuthStore`; local email verifier records in Keychain, non-secret session in UserDefaults, and native AuthenticationServices for Apple
- **Routines**: `CommuteRoutineStore` in the shared App Group
- **Navigation**: `AppRouter` parses TrafficVienna destinations; the `trafficvienna://` custom scheme is registered in the app Info.plist; station directions use `MKMapItem` and Apple Maps
- **StationStore**: `@Published` + `StationStoring` protocol, loads bundled JSON (`wienerlinien-ogd-haltestellen.json`)
- **DTOs** (DTO.swift): `MonitorResponse`, `Monitor`, `Lines`, `DepartureTime` — all `nonisolated` + `Sendable`, lenient decoding
- **Live Activities and widgets**: ActivityKit plus a WidgetKit/AppIntent extension. Widgets support small, medium, large, accessory circular, accessory rectangular, and accessory inline families.
- **Shared logic** in `WidgetShared/`: RouteMatching, LineColors, DepartureActivityAttributes, widget cache DTOs, merge ordering, batch loading, and fetch-time countdown projection
- **Concurrency**: async/await for network work; Combine-backed observable state for SwiftUI models

## What good looks like

- The app loads quickly, with cached responses and coalesced network requests staying well within Wiener Linien's rate limit.
- Departure times update every 30 seconds on screen without flicker or redundant API calls.
- The UI gracefully handles missing location permissions, network errors, rate limiting, and empty states with a useful next action.
- Map markers remain bounded and reduce in density as the visible region widens.
- All user-facing strings are localised in English, German, and Ukrainian via string catalogs.
- The widget and app share station-matching logic from `WidgetShared/`.

## Out of scope

- Android / watchOS / macOS versions.
- Real-time vehicle tracking on the map (the API only provides stop-level departure counts).
- Server-backed accounts, password recovery, and cross-device favourites sync. Current email accounts are device-local.
- In-app ticket purchase or A→B route calculation. The app can open the official ticket companion and Apple Maps, but does not impersonate either service.
- Remote push notifications. Departure reminders are local notifications.
