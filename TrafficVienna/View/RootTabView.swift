import SwiftUI
import Combine
import Network

@MainActor
final class NetworkMonitor: ObservableObject {
    @Published private(set) var isConnected = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            Task { @MainActor [weak self] in
                self?.isConnected = connected
            }
        }
        monitor.start(queue: queue)
        isConnected = monitor.currentPath.status == .satisfied
    }

    deinit { monitor.cancel() }
}

private enum AppTab: String { case nearby, search, map, alerts, favourites }

struct RootTabView: View {
    @EnvironmentObject private var router: AppRouter
    @StateObject private var store = StationStore()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var favoritesVM = FavoritesListViewModel()
    @StateObject private var disruptionsVM = DisruptionsViewModel()
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var themeManager = ThemeManager.shared
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var selectedTab: AppTab = .nearby
    @State private var routedStation: Station?

    var body: some View {
        tabs
            .overlay(alignment: .top) {
                if !networkMonitor.isConnected {
                    Text("Offline")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.appOfflineBg)
                        .padding(.top, 4)
                }
            }
            .tint(themeManager.preset.accentColor)
            .preferredColorScheme(themeManager.preset.colorScheme)
            .fullScreenCover(isPresented: Binding(get: { !hasOnboarded }, set: { _ in })) {
                OnboardingView {
                    locationManager.requestLocationIfNeeded()
                    hasOnboarded = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .init("shortcut"))) { note in
                guard let type = note.object as? String else { return }
                withAnimation { selectedTab = AppTab(rawValue: type) ?? .nearby }
            }
            .onChange(of: router.destination) { _, destination in
                guard let destination else { return }
                switch destination {
                case .nearby: selectedTab = .nearby
                case .search: selectedTab = .search
                case .map: selectedTab = .map
                case .alerts: selectedTab = .alerts
                case .favourites: selectedTab = .favourites
                case .station(let id): routedStation = store.station(id: id)
                }
                router.consume()
            }
            .onChange(of: favoritesVM.favoriteRoutes, initial: true) { _, routes in
                disruptionsVM.updateFavoriteRoutes(routes)
            }
            .sheet(item: $routedStation) { station in
                NavigationStack { StationDetailView(station: station) }
            }
            .environmentObject(themeManager)
            .environmentObject(favoritesVM)
    }

    private var tabs: some View {
        TabView(selection: $selectedTab) {
            Tab("Nearby", systemImage: "location.fill", value: .nearby) {
                NavigationStack {
                    NearbyView(
                        store: store,
                        locationManager: locationManager,
                        favoritesVM: favoritesVM,
                        disruptionsVM: disruptionsVM,
                        isActive: selectedTab == .nearby
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
                    DisruptionsView(vm: disruptionsVM, isActive: selectedTab == .alerts)
                }
            }
            .badge(disruptionsVM.infos.count)

            Tab("Favourites", systemImage: "star.fill", value: .favourites) {
                NavigationStack {
                    FavoritesView(vm: favoritesVM, isActive: selectedTab == .favourites)
                }
            }
        }
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

#Preview {
    RootTabView()
}
