# TrafficVienna — Context

## What we're building

A SwiftUI iOS app for live Wiener Linien (Vienna public transport) departures. The app shows nearby stops, lets users search for any station, view live departure boards grouped by platform, save favourite stations and line/direction pairs, browse network-wide service alerts, explore stations on a map, schedule local departure reminders, and track a selected departure on the Lock Screen via Live Activities. Configurable Home Screen and Lock Screen widgets show departures for selected favourite routes.

### Architecture

- **4 tabs** (`RootTabView`): Home, Discover, Alerts, Saved. Discover owns both
  station search and map exploration; the shared external destination vocabulary
  continues to route Nearby, Search, and Favourites intents to the matching new
  journey.
- **MVVM** — feature state lives in focused ViewModels, primarily via Observation
  (`@Observable`), with narrow `ObservableObject` wrappers for Core Location,
  connectivity, station catalogue, and system-routing integration.
- **Key ViewModels**: StationDetailViewModel, NearbyViewModel, DisruptionsViewModel, FavoritesListViewModel
- **Services**: MonitorService (actor, centralises API calls with caching + coalescing + throttling + rate-limit backoff), NetworkManager (protocol-based), LocationManager (CLLocationManager wrapper)
- **Storage**: UserDefaults-based repositories for favourites (FavoriteRoute, FavoriteStation), RecentSearchesStore
- **StationStore**: `@Published` + `StationStoring` protocol, loads bundled JSON (`wienerlinien-ogd-haltestellen.json`)
- **DTOs** (DTO.swift): `MonitorResponse`, `Monitor`, `Lines`, `DepartureTime` — all `nonisolated` + `Sendable`, lenient decoding
- **System surfaces**: local departure notifications via UserNotifications;
  ActivityKit tracking with explicit update/end lifecycle; configurable Home
  Screen and Lock Screen widgets via WidgetKit + App Intents. Notification taps
  use the persisted typed router to open the matching station in Discover.
- **Shared logic** in `WidgetShared/`: RouteMatching, LineColors, DepartureActivityAttributes
- **Concurrency**: async/await throughout feature services; Combine is limited to
  the small system-facing wrappers above.
- **Regression surfaces**: `TrafficViennaTests` covers model and service behavior;
  `TrafficViennaUITests` proves the four-tab shell, Discover-to-map reachability,
  alert filters, Saved, and station search-to-detail navigation.

## What good looks like

- The app loads quickly, with cached responses and coalesced network requests staying well within Wiener Linien's rate limit.
- Visible departure boards refresh every 60 seconds without flicker or redundant
  API calls; widgets use system-rendered dynamic countdown dates between bounded
  five-minute refresh opportunities, plus boundary entries that promptly remove
  departed rows.
- Core Location requests are one-shot and coalesced rather than continuously
  tracking the user.
- The UI gracefully handles missing location permissions, network errors, rate limiting, and empty states.
- All user-facing strings are localised (English and German via `Localizable.xcstrings`).
- The widget and app share station-matching logic from `WidgetShared/`.

## Out of scope

- Android / watchOS / macOS versions.
- Real-time vehicle tracking on the map (the API only provides stop-level departure counts).
- Accounts or gating live transport data behind login. Identity should return only
  with a real cross-device feature, complete deletion lifecycle, and approved
  backend/provider boundary.
- Ticket purchase or routing between stations.
- Remote push notifications for network disruptions. They require an owned
  backend and APNs provider; the app intentionally supports only user-created
  local departure reminders without claiming remote delivery.
