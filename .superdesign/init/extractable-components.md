# Extractable components

The source is native SwiftUI, while Superdesign reusable components use HTML templates. The items below are the stable product patterns worth translating. Simple system buttons and inputs should stay inline.

## RootTabBar

- Source: `TrafficVienna/View/RootTabView.swift`
- Category: layout
- Description: Five-item iPhone bottom tab bar for Nearby, Search, Map, Alerts, and Favourites.
- Extractable props: `activeItem` (string, default `nearby`), `alertCount` (number, default `0`), `showOffline` (boolean, default `false`).
- Hardcoded: tab labels, SF Symbol names, ordering, safe-area placement.

## OnboardingShell

- Source: `TrafficVienna/View/OnboardingView.swift`
- Category: layout
- Description: Full-screen three-page onboarding shell with pager dots, a primary action, and anonymous-use reassurance.
- Extractable props: `currentStep` (number, default `0`), `isLastStep` (boolean, default `false`).
- Hardcoded: page sequence, button placement, privacy message.

## FavoriteNextDepartureCard

- Source: `TrafficVienna/View/Components/FavoriteNextDepartureCard.swift`
- Category: basic
- Description: Featured live departure hero with route, destination, station, countdown, and live/saved status.
- Extractable props: `line`, `destination`, `station`, `minutes`, `isLive`, `isSaved`.
- Hardcoded: information hierarchy, arrow action, route-badge treatment.

## ServiceStatusCard

- Source: `TrafficVienna/View/Components/ServiceStatusCard.swift`
- Category: basic
- Description: Compact service-health summary with loading, all-clear, alert, saved, and unavailable states.
- Extractable props: `state`, `alertCount`, `isSaved`.
- Hardcoded: title, icons, chevron, status color semantics.

## StationCard

- Source: `TrafficVienna/View/StationCardView.swift`
- Category: basic
- Description: Nearby station card with walking distance, line badges, freshness, and live departure rows.
- Extractable props: `stationName`, `walkingMinutes`, `distance`, `isSaved`, `lines`.
- Hardcoded: four-row limit, spacing, dividers, status hierarchy.

## DepartureLineRow

- Source: `TrafficVienna/View/Components/DepartureLineRow.swift`
- Category: basic
- Description: Reusable transit line row with badge, destination, next/follow-up times, live signal, disruption, and walking feasibility.
- Extractable props: `line`, `destination`, `minutes`, `hasDisruption`, `isLive`, `walkMinutes`.
- Hardcoded: compact and accessibility layouts, timing hierarchy.

## FilterChip

- Source: `TrafficVienna/View/Components/FilterChip.swift`
- Category: basic
- Description: Accessible capsule filter with selected and unselected states.
- Extractable props: `title`, `selected`, `color`.
- Hardcoded: 44-point minimum hit target and type treatment.

## MapStationSelectionCard

- Source: `TrafficVienna/View/MapStationSelectionCard.swift`
- Category: basic
- Description: Bottom safe-area station preview layered over the map.
- Extractable props: `stationName`, `lines`.
- Hardcoded: close control, navigation affordance, bottom-sheet geometry.
