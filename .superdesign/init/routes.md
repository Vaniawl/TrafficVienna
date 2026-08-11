# Journey and navigation map

TrafficVienna is a native SwiftUI iPhone app. It does not use URL routing for internal navigation; `RootTabView` owns five enum-backed tabs and each tab owns an independent `NavigationStack`.

## App entry

- First launch: `TrafficVienna/TrafficViennaApp.swift` → `RootTabView` → `OnboardingView`.
- Returning launch: `TrafficVienna/TrafficViennaApp.swift` → `RootTabView` → selected tab.
- Valid external destinations: Nearby, Search, and Favourites through the typed `TrafficViennaDestination` handoff.

## Primary tabs

| Destination | Entry view | Navigation title | Main detail destination |
| --- | --- | --- | --- |
| Nearby | `TrafficVienna/View/NearbyView.swift` | Nearby | `StationDetailView` |
| Search | `TrafficVienna/View/SearchView.swift` | Search | `StationDetailView` |
| Map | `TrafficVienna/View/MapStationsView.swift` | Map | `StationDetailView` |
| Alerts | `TrafficVienna/View/DisruptionsView.swift` | Alerts | `DisruptionDetailView` |
| Favourites | `TrafficVienna/View/FavoritesView.swift` | Favourites | `StationDetailView`, `AboutView` sheet |

## Full tab vocabulary

Source: `TrafficVienna/Model/AppTab.swift`

```swift
import Foundation

enum AppTab: Hashable {
    case nearby
    case search
    case map
    case alerts
    case favourites
}
```

## Important presentation routes

- `OnboardingView` is a three-step page-style `TabView` followed by the main tab shell.
- `StationDetailView` presents live departures, filters, service alerts, favourites, refresh, and Live Activity actions.
- `DisruptionDetailView` is pushed from Alerts and Station Detail.
- `AboutView` is a sheet from Favourites.
- Map station selection first appears as a bottom card and then pushes Station Detail.
