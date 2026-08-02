# TrafficVienna

## Product

TrafficVienna is a native SwiftUI iOS application for Vienna public transport.
It helps residents and visitors find nearby stops, search and browse stations,
inspect live departures and disruptions, save favourites, and use local system
surfaces for time-sensitive departures.

## Audience

- Daily Wiener Linien passengers who need fast departure information.
- Visitors who need a clear station search and map experience.
- Users relying on Dynamic Type, VoiceOver, localisation, or reduced motion.

## Current product scope

- Four primary journeys: Home, Discover, Alerts, and Saved. Discover owns search
  and map exploration.
- Live departure and disruption data from fixed public Wiener Linien endpoints.
- Bundled station data for local search and map markers.
- Local favourites and recent searches through UserDefaults/App Group storage.
- Location-aware nearby stops with a Vienna-centre fallback.
- User-created local departure reminders through UserNotifications.
- Configurable Home/Lock Screen widgets and explicit Live Activity tracking.
- English and German strings in app and widget string catalogues.

## Stack and architecture

- Swift and SwiftUI with async/await.
- MVVM-style views and observable view models.
- `MonitorService` actor for API caching, request coalescing, throttling, and
  backoff.
- Protocol boundaries for network, location, storage, notifications, and
  ActivityKit testability.
- Shared app/widget logic under `TrafficVienna/WidgetShared/`.
- XCTest and XCUITest targets in the shared Xcode scheme.

## Boundaries

The active goal may improve design, accessibility, maintainability, performance,
failure handling, and test coverage while preserving useful behaviour. Android,
ticket sales, route planning, remote disruption push, accounts, and production
deployment are outside the current scope. Identity can return only with a real
cross-device feature, complete deletion lifecycle, and an explicitly approved
backend/provider boundary.

## Sources of truth

The root state files define the active goal. Current source and observed command
results override older narrative documentation. `docs/CONTEXT.md` and
`docs/REFERENCES.md` provide product background. Files under `memory/` preserve
dated implementation history and architectural decisions.
