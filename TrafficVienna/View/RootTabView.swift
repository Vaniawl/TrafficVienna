import SwiftUI

struct RootTabView: View {
    @StateObject private var store = StationStore()
    @StateObject private var locationManager = LocationManager()
    @State private var favoritesVM = FavoritesListViewModel()
    @State private var disruptionsVM = DisruptionsViewModel()
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var shortcutRouter = TrafficViennaShortcutRouter.shared
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var navigation = RootNavigationState()
    @State private var isShowingAbout = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if hasOnboarded {
                TabView(selection: $navigation.selectedTab) {
                    Tab("Home", systemImage: "location.fill", value: .nearby) {
                        NavigationStack(path: $navigation.nearbyPath) {
                            NearbyView(
                                store: store,
                                locationManager: locationManager,
                                favoritesViewModel: favoritesVM,
                                disruptionsViewModel: disruptionsVM,
                                onShowFavourites: showFavourites,
                                onShowAlerts: showAlerts,
                                onShowAbout: { isShowingAbout = true }
                            )
                        }
                    }

                    Tab("Discover", systemImage: "magnifyingglass", value: .search) {
                        NavigationStack(path: $navigation.discoverPath) {
                            SearchView(
                                store: store,
                                locationManager: locationManager,
                                favoritesViewModel: favoritesVM
                            )
                        }
                    }

                    Tab("Alerts", systemImage: "exclamationmark.triangle.fill", value: .alerts) {
                        NavigationStack(path: $navigation.alertsPath) {
                            DisruptionsView(viewModel: disruptionsVM)
                        }
                    }
                    .badge(disruptionsVM.badgeCount)

                    Tab("Saved", systemImage: "star.fill", value: .favourites) {
                        NavigationStack(path: $navigation.favouritesPath) {
                            FavoritesView(
                                viewModel: favoritesVM,
                                store: store,
                                onDiscover: showDiscover
                            )
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
                    isShowingAbout = false
                    withAnimation(Motion.quick(reduceMotion: reduceMotion)) {
                        navigation.openExternalDestination(destination)
                    }
                    shortcutRouter.consume()
                }
                .onChange(of: shortcutRouter.pendingStationID, initial: true) { _, stationID in
                    guard let stationID else { return }
                    isShowingAbout = false
                    let station = store.stations.first { $0.id == stationID }
                    withAnimation(Motion.quick(reduceMotion: reduceMotion)) {
                        navigation.openExternalStation(station)
                    }
                    shortcutRouter.consumeStation()
                }
                .onReceive(NotificationCenter.default.publisher(for: .favoriteStationsDidChange)) { _ in
                    favoritesVM.loadStations()
                }
                .onReceive(NotificationCenter.default.publisher(for: .favoriteRoutesDidChange)) { _ in
                    Task { await favoritesVM.loadFavorites() }
                }
                .onChange(of: favoritesVM.items.map(\.route), initial: true) { _, routes in
                    disruptionsVM.updateRelevantLines(Set(routes.map(\.lineName)))
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
        .sheet(isPresented: $isShowingAbout) {
            AboutView()
        }
    }

    private func showFavourites() {
        select(.favourites)
    }

    private func showAlerts() {
        select(.alerts)
    }

    private func showDiscover() {
        select(.search)
    }

    private func select(_ tab: AppTab) {
        withAnimation(Motion.quick(reduceMotion: reduceMotion)) {
            navigation.select(tab)
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
