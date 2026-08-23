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

- Five primary tabs: Nearby, Search, Map, Alerts, and Favourites, using one
  adaptive visual identity rather than selectable design presets.
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
- Embedded English/German localisation catalogues for both app and widget.
- Xcode project with application, widget extension, and XCTest targets verified
  on the macOS iPhone 17 simulator.

## Boundaries

The active goal may improve design, accessibility, maintainability,
performance, failure handling, and test coverage while preserving useful
behaviour. Android, ticket sales, route planning, accounts, server-side sync,
and production deployment are outside the current scope. Traffic information,
favourites, recents, widgets, and Live Activities remain anonymous and local.
The app retains only an idempotent migration that removes obsolete device-only
account data from earlier builds.

## Sources of truth

The root product state files define the active goal; `AGENTS.md` and
`docs/opencode/` define the workflow. Current source and observed command results
override older narrative documentation. `memory/JOURNAL.md` and
`memory/DECISIONS.md` retain newest-first project evidence and durable decisions.
