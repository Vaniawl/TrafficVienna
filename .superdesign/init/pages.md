# Key screen dependency trees

## Onboarding

Entry: `TrafficVienna/View/OnboardingView.swift`

Dependencies:
- `TrafficVienna/View/OnboardingPageView.swift`
  - `TrafficVienna/Model/OnboardingStep.swift`
  - `TrafficVienna/Model/Spacing.swift`
  - `TrafficVienna/Model/CornerRadius.swift`
  - `TrafficVienna/Model/DesignColor.swift`
  - `TrafficVienna/Model/Motion.swift`

## Nearby dashboard

Entry: `TrafficVienna/View/NearbyView.swift`

Dependencies:
- `TrafficVienna/Model/NearbyViewModel.swift`
- `TrafficVienna/Model/NearbyDashboardState.swift`
- `TrafficVienna/View/Components/FavoriteNextDepartureCard.swift`
- `TrafficVienna/View/Components/ServiceStatusCard.swift`
- `TrafficVienna/View/Components/FavoriteStationsQuickAccessView.swift`
  - `TrafficVienna/View/Components/FavoriteStationQuickAccessCard.swift`
- `TrafficVienna/View/Components/NearbyStatusCard.swift`
- `TrafficVienna/View/StationCardView.swift`
  - `TrafficVienna/View/Components/DepartureLineRow.swift`
  - `TrafficVienna/View/Components/LineStyle.swift`
  - `TrafficVienna/View/Components/Shimmer.swift`
- `TrafficVienna/View/StationDetailView.swift`

## Search

Entry: `TrafficVienna/View/SearchView.swift`

Dependencies:
- `TrafficVienna/Model/SearchViewModel.swift`
- `TrafficVienna/Model/SearchStatus.swift`
- `TrafficVienna/View/RecentStationsList.swift`
- `TrafficVienna/View/SearchResultsList.swift`
  - `TrafficVienna/View/SearchStationRow.swift`
- `TrafficVienna/View/StationDetailView.swift`

## Station detail

Entry: `TrafficVienna/View/StationDetailView.swift`

Dependencies:
- `TrafficVienna/Model/StationDetailViewModel.swift`
- `TrafficVienna/Model/StationDetailState.swift`
- `TrafficVienna/View/StationDeparturesList.swift`
  - `TrafficVienna/View/StationFreshnessBar.swift`
  - `TrafficVienna/View/StationDepartureRow.swift`
  - `TrafficVienna/View/Components/FilterChips.swift`
    - `TrafficVienna/View/Components/FilterChip.swift`
  - `TrafficVienna/View/Components/DisruptionRow.swift`
- `TrafficVienna/View/DisruptionDetailView.swift`

## Map

Entry: `TrafficVienna/View/MapStationsView.swift`

Dependencies:
- `TrafficVienna/Model/MapStationsViewModel.swift`
- `TrafficVienna/View/MapContentOverlay.swift`
- `TrafficVienna/View/MapLocationBannerView.swift`
- `TrafficVienna/View/MapStationSelectionCard.swift`
- `TrafficVienna/View/StationDetailView.swift`

## Alerts

Entry: `TrafficVienna/View/DisruptionsView.swift`

Dependencies:
- `TrafficVienna/Model/DisruptionsViewModel.swift`
- `TrafficVienna/View/DisruptionsList.swift`
  - `TrafficVienna/View/Components/DisruptionKindPicker.swift`
  - `TrafficVienna/View/Components/DisruptionRow.swift`
- `TrafficVienna/View/DisruptionDetailView.swift`

## Favourites

Entry: `TrafficVienna/View/FavoritesView.swift`

Dependencies:
- `TrafficVienna/Model/FavoritesListViewModel.swift`
- `TrafficVienna/View/Components/DepartureLineRow.swift`
- `TrafficVienna/View/StationDetailView.swift`
- `TrafficVienna/View/AboutView.swift`
