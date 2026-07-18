# TrafficVienna — Context

## What we're building

A SwiftUI iOS app for live Wiener Linien (Vienna public transport) departures. The app shows nearby stops, lets users search for any station, view live departure boards grouped by platform, save favourite stations and line/direction pairs, browse network-wide service alerts, explore stations on a map, and track a selected departure on the Lock Screen via Live Activities. A home-screen widget shows departures for the user's favourite station.

### Architecture

- **5 tabs** (RootTabView): Nearby, Search, Map, Alerts, Favourites
- **MVVM** — views are dumb, state lives in ViewModels via `@Published`
- **Key ViewModels**: StationDetailViewModel, NearbyViewModel, DisruptionsViewModel, FavoritesListViewModel
- **Services**: MonitorService (actor, centralises API calls with caching + coalescing + throttling + rate-limit backoff), NetworkManager (protocol-based), LocationManager (CLLocationManager wrapper)
- **Storage**: UserDefaults-based repositories for favourites (FavoriteRoute, FavoriteStation), RecentSearchesStore
- **StationStore**: `@Published` + `StationStoring` protocol, loads bundled JSON (`wienerlinien-ogd-haltestellen.json`)
- **DTOs** (DTO.swift): `MonitorResponse`, `Monitor`, `Lines`, `DepartureTime` — all `nonisolated` + `Sendable`, lenient decoding
- **Live Activities**: via ActivityKit (LiveActivityController) + WidgetExtension with AppIntent
- **Shared logic** in `WidgetShared/`: RouteMatching, LineColors, DepartureActivityAttributes
- **No Combine** — async/await throughout

## What good looks like

- The app loads quickly, with cached responses and coalesced network requests staying well within Wiener Linien's rate limit.
- Departure times update every 30 seconds on screen without flicker or redundant API calls.
- The UI gracefully handles missing location permissions, network errors, rate limiting, and empty states.
- All user-facing strings are localised (English and German via `Localizable.xcstrings`).
- The widget and app share station-matching logic from `WidgetShared/`.

## Out of scope

- Android / watchOS / macOS versions.
- Real-time vehicle tracking on the map (the API only provides stop-level departure counts).
- Mandatory accounts or gating live transport data behind login. Optional account
  access is an active product goal; cross-device favourite sync remains a separate
  future decision.
- Ticket purchase or routing between stations.
- Push notifications (only local Live Activities and widget timelines are used).
