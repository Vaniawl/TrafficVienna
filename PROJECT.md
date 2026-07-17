# TrafficVienna

## Product

TrafficVienna is a native SwiftUI iOS application for Vienna public transport.
It helps residents and visitors find nearby stops, search stations, inspect live
departures and disruptions, save favourites, browse stops on a map, and use a
home-screen widget and Live Activity.

## Audience

- Daily Wiener Linien passengers who need fast departure information.
- Visitors who need a clear station search and map experience.
- Users relying on Dynamic Type, VoiceOver, localisation, or reduced-motion
  accessibility settings.

## Current product scope

- Five primary tabs: Nearby, Search, Map, Alerts, and Favourites.
- Live departure and disruption data from public Wiener Linien endpoints.
- Bundled station data for local search and map markers.
- Local favourites and recent searches through `UserDefaults`.
- Location-aware nearby stops with a Vienna-centre fallback.
- Widget and Live Activity support through the widget extension.
- English and German strings in `TrafficVienna/Localizable.xcstrings`.

## Stack and architecture

- Swift and SwiftUI with async/await.
- MVVM-style views and observable view models.
- `MonitorService` actor for API caching, request coalescing, throttling, and
  backoff.
- `NetworkManager` protocol boundary for network testability.
- Shared app/widget logic under `TrafficVienna/WidgetShared/`.
- Xcode project with application and widget extension targets. The repository
  contains Swift tests, but test-target wiring must be verified on macOS.

## Boundaries

The active goal may improve design, accessibility, maintainability,
performance, failure handling, and test coverage while preserving useful
behaviour. Android, accounts, server-side synchronisation, ticket sales,
route planning, production deployment, and new external services are outside
the current scope.

## Sources of truth

The root state files define the active goal. Current source and observed command
results override older narrative documentation. `docs/CONTEXT.md` and
`docs/REFERENCES.md` provide product background. Files under `memory/` are
historical and are not autonomous workflow state.

