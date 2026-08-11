# Shared layouts

## `TrafficVienna/TrafficViennaApp.swift`

Application entry point. It presents the root journey, applies the app accent globally, and runs the legacy-account cleanup task.

```swift
//
//  TrafficViennaApp.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 07.11.25.
//

import SwiftUI

@main
struct TrafficViennaApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(.appAccent)
                .task {
                    LegacyAccountProfileCleanup.run()
                }
        }
    }
}
```

## `TrafficVienna/View/RootTabView.swift`

Root app shell. Before onboarding it shows the paged introduction. Afterwards it owns the five-tab iPhone navigation, shared favourites and disruption state, offline banner, deep-link handoff, and refresh lifecycles.

```swift
import SwiftUI

struct RootTabView: View {
    @StateObject private var store = StationStore()
    @StateObject private var locationManager = LocationManager()
    @State private var favoritesVM = FavoritesListViewModel()
    @State private var disruptionsVM = DisruptionsViewModel()
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var shortcutRouter = TrafficViennaShortcutRouter.shared
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var selectedTab: AppTab = .nearby
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if hasOnboarded {
                TabView(selection: $selectedTab) {
                    Tab("Nearby", systemImage: "location.fill", value: .nearby) {
                        NavigationStack {
                            NearbyView(
                                store: store,
                                locationManager: locationManager,
                                favoritesViewModel: favoritesVM,
                                disruptionsViewModel: disruptionsVM,
                                onShowFavourites: showFavourites,
                                onShowAlerts: showAlerts
                            )
                        }
                    }

                    Tab("Search", systemImage: "magnifyingglass", value: .search) {
                        NavigationStack {
                            SearchView(store: store)
                        }
                    }

                    Tab("Map", systemImage: "map.fill", value: .map) {
                        NavigationStack {
                            MapStationsView(store: store, locationManager: locationManager)
                        }
                    }

                    Tab("Alerts", systemImage: "exclamationmark.triangle.fill", value: .alerts) {
                        NavigationStack {
                            DisruptionsView(viewModel: disruptionsVM)
                        }
                    }
                    .badge(disruptionsVM.activeServiceCount)

                    Tab("Favourites", systemImage: "star.fill", value: .favourites) {
                        NavigationStack {
                            FavoritesView(viewModel: favoritesVM)
                        }
                    }
                }
                .overlay(alignment: .top) {
                    if !networkMonitor.isConnected {
                        OfflineStatusView()
                            .transition(Motion.edgeTransition(.top, reduceMotion: reduceMotion))
                    }
                }
                .animation(
                    Motion.quick(reduceMotion: reduceMotion),
                    value: networkMonitor.isConnected
                )
                .onChange(of: shortcutRouter.pendingDestination, initial: true) { _, destination in
                    guard let destination else { return }
                    select(destination.appTab)
                    shortcutRouter.consume()
                }
                .onReceive(NotificationCenter.default.publisher(for: .favoriteStationsDidChange)) { _ in
                    favoritesVM.loadStations()
                }
                .onReceive(NotificationCenter.default.publisher(for: .favoriteRoutesDidChange)) { _ in
                    Task { await favoritesVM.loadFavorites() }
                }
                .task {
                    await refreshFavouritesContinuously()
                }
                .task {
                    await refreshDisruptionsContinuously()
                }
                .transition(Motion.stateTransition(reduceMotion: reduceMotion))
            } else {
                OnboardingView {
                    locationManager.requestLocationIfNeeded()
                    hasOnboarded = true
                }
                .transition(Motion.stateTransition(reduceMotion: reduceMotion))
            }
        }
        .animation(Motion.standard(reduceMotion: reduceMotion), value: hasOnboarded)
        .onOpenURL { url in
            shortcutRouter.handle(deepLinkURL: url)
        }
    }

    private func showFavourites() {
        select(.favourites)
    }

    private func showAlerts() {
        select(.alerts)
    }

    private func select(_ tab: AppTab) {
        withAnimation(Motion.quick(reduceMotion: reduceMotion)) {
            selectedTab = tab
        }
    }

    private func refreshFavouritesContinuously() async {
        favoritesVM.loadStations()

        while !Task.isCancelled {
            await favoritesVM.loadFavorites()
            do {
                try await Task.sleep(for: .seconds(60))
            } catch {
                break
            }
        }
    }

    private func refreshDisruptionsContinuously() async {
        while !Task.isCancelled {
            await disruptionsVM.load()
            do {
                try await Task.sleep(for: .seconds(120))
            } catch {
                break
            }
        }
    }
}

#Preview {
    RootTabView()
}
```
