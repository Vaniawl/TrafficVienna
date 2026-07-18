import SwiftUI

struct RootTabView: View {
    @StateObject private var store = StationStore()
    @StateObject private var locationManager = LocationManager()
    @State private var favoritesVM = FavoritesListViewModel()
    @State private var disruptionsVM = DisruptionsViewModel()
    @StateObject private var networkMonitor = NetworkMonitor()
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
                .onReceive(NotificationCenter.default.publisher(for: .init("shortcut"))) { note in
                    guard let type = note.object as? String else { return }
                    withAnimation(Motion.quick(reduceMotion: reduceMotion)) {
                        selectedTab = AppTab(rawValue: type) ?? .nearby
                    }
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
    }

    private func showFavourites() {
        withAnimation(Motion.quick(reduceMotion: reduceMotion)) {
            selectedTab = .favourites
        }
    }

    private func showAlerts() {
        withAnimation(Motion.quick(reduceMotion: reduceMotion)) {
            selectedTab = .alerts
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
