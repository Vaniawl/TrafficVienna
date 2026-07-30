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
                    Tab("Home", systemImage: "location.fill", value: .nearby) {
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

                    Tab("Discover", systemImage: "magnifyingglass", value: .search) {
                        NavigationStack {
                            SearchView(
                                store: store,
                                locationManager: locationManager,
                                favoritesViewModel: favoritesVM
                            )
                        }
                    }

                    Tab("Alerts", systemImage: "exclamationmark.triangle.fill", value: .alerts) {
                        NavigationStack {
                            DisruptionsView(viewModel: disruptionsVM)
                        }
                    }
                    .badge(disruptionsVM.badgeCount)

                    Tab("Saved", systemImage: "star.fill", value: .favourites) {
                        NavigationStack {
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
                    select(destination.appTab)
                    shortcutRouter.consume()
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
