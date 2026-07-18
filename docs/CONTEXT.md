# TrafficVienna — Context

## What we're building

A SwiftUI iOS app for live Wiener Linien (Vienna public transport) departures. The app shows nearby stops, lets users search for any station, view live departure boards grouped by platform, save favourite stations and line/direction pairs, browse network-wide service alerts, explore stations on a map, and track a selected departure on the Lock Screen via Live Activities. A home-screen widget shows departures for the user's favourite station.

The app also has a device-local authentication gate, a neobank-style dashboard, commute routines, personalised disruption priority, departure reminders, offline stale-response fallback, and tested deep-link routing foundations.

### Architecture

- **5 tabs** (RootTabView): Nearby, Search, Map, Alerts, Favourites
- **MVVM** — views are dumb, state lives in ViewModels via `@Published`
- **Key ViewModels**: StationDetailViewModel, NearbyViewModel, DisruptionsViewModel, FavoritesListViewModel
- **Services**: MonitorService (actor, centralises API calls with caching + coalescing + throttling + rate-limit backoff), NetworkManager (protocol-based), LocationManager (CLLocationManager wrapper)
- **Storage**: UserDefaults-based repositories for favourites (FavoriteRoute, FavoriteStation), RecentSearchesStore
- **Authentication**: `AuthStore`; local email verifier records in Keychain, non-secret session in UserDefaults, and native AuthenticationServices for Apple
- **Routines**: `CommuteRoutineStore` in the shared App Group
- **Navigation**: `AppRouter` parses TrafficVienna destinations; the `trafficvienna://` custom scheme is registered in the app Info.plist
- **StationStore**: `@Published` + `StationStoring` protocol, loads bundled JSON (`wienerlinien-ogd-haltestellen.json`)
- **DTOs** (DTO.swift): `MonitorResponse`, `Monitor`, `Lines`, `DepartureTime` — all `nonisolated` + `Sendable`, lenient decoding
- **Live Activities**: via ActivityKit (LiveActivityController) + WidgetExtension with AppIntent
- **Shared logic** in `WidgetShared/`: RouteMatching, LineColors, DepartureActivityAttributes
- **Concurrency**: async/await for network work; Combine-backed observable state for SwiftUI models

## What good looks like

- The app loads quickly, with cached responses and coalesced network requests staying well within Wiener Linien's rate limit.
- Departure times update every 30 seconds on screen without flicker or redundant API calls.
- The UI gracefully handles missing location permissions, network errors, rate limiting, and empty states.
- All user-facing strings are localised (English and German via `Localizable.xcstrings`).
- The widget and app share station-matching logic from `WidgetShared/`.

## Out of scope

- Android / watchOS / macOS versions.
- Real-time vehicle tracking on the map (the API only provides stop-level departure counts).
- Server-backed accounts, password recovery, and cross-device favourites sync. Current email accounts are device-local.
- Ticket purchase or routing between stations.
- Remote push notifications. Departure reminders are local notifications.
