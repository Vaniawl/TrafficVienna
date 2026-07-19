import SwiftUI
import Combine
import Network
import UIKit

@MainActor
final class NetworkMonitor: ObservableObject {
    @Published private(set) var isConnected = true
    @Published private(set) var isConstrained = false
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            let constrained = path.isConstrained
            Task { @MainActor [weak self] in
                self?.isConnected = connected
                self?.isConstrained = constrained
            }
        }
        monitor.start(queue: queue)
        isConnected = monitor.currentPath.status == .satisfied
        isConstrained = monitor.currentPath.isConstrained
    }

    deinit { monitor.cancel() }
}

@MainActor
final class MemoryPressureCoordinator {
    private let notificationCenter: NotificationCenter
    private var observer: NSObjectProtocol?

    init(
        notificationCenter: NotificationCenter = .default,
        service: MonitorService = .shared
    ) {
        self.notificationCenter = notificationCenter
        observer = notificationCenter.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { await service.releaseCachedResponses() }
        }
    }

    deinit {
        if let observer {
            notificationCenter.removeObserver(observer)
        }
    }
}

private enum AppTab: String { case nearby, search, map, alerts, favourites }

@MainActor
final class RootTabState: ObservableObject {
    private let memoryPressureCoordinator = MemoryPressureCoordinator()
    let store = StationStore(loadSynchronously: false)
    let locationManager = LocationManager()
    let favoritesVM = FavoritesListViewModel()
    let recentSearches = RecentSearchesStore()
    let disruptionsVM = DisruptionsViewModel()
    let networkMonitor = NetworkMonitor()
    let energyMonitor = EnergyMonitor()
    let themeManager = ThemeManager.shared
    let homePreferences = HomePreferences()
    @Published fileprivate var selectedTab: AppTab = .nearby
    @Published var routedStation: Station?
}

struct RootTabView: View {
    @EnvironmentObject private var router: AppRouter
    @ObservedObject private var state: RootTabState
    @ObservedObject private var store: StationStore
    @ObservedObject private var locationManager: LocationManager
    @ObservedObject private var favoritesVM: FavoritesListViewModel
    @ObservedObject private var recentSearches: RecentSearchesStore
    @ObservedObject private var disruptionsVM: DisruptionsViewModel
    @ObservedObject private var networkMonitor: NetworkMonitor
    @ObservedObject private var energyMonitor: EnergyMonitor
    @ObservedObject private var themeManager: ThemeManager
    @ObservedObject private var homePreferences: HomePreferences
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    init(state: RootTabState) {
        _state = ObservedObject(wrappedValue: state)
        _store = ObservedObject(wrappedValue: state.store)
        _locationManager = ObservedObject(wrappedValue: state.locationManager)
        _favoritesVM = ObservedObject(wrappedValue: state.favoritesVM)
        _recentSearches = ObservedObject(wrappedValue: state.recentSearches)
        _disruptionsVM = ObservedObject(wrappedValue: state.disruptionsVM)
        _networkMonitor = ObservedObject(wrappedValue: state.networkMonitor)
        _energyMonitor = ObservedObject(wrappedValue: state.energyMonitor)
        _themeManager = ObservedObject(wrappedValue: state.themeManager)
        _homePreferences = ObservedObject(wrappedValue: state.homePreferences)
    }

    var body: some View {
        Group {
            if store.isReady {
                tabs
            } else {
                VStack(spacing: 14) {
                    ProgressView()
                    Text("Preparing Vienna…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            }
        }
            .overlay(alignment: .top) {
                if !networkMonitor.isConnected || networkMonitor.isConstrained {
                    Text(networkMonitor.isConnected ? LocalizedStringKey("Low Data") : LocalizedStringKey("Offline"))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(networkMonitor.isConnected ? Color.orange : Color.red)
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
                withAnimation { state.selectedTab = AppTab(rawValue: type) ?? .nearby }
            }
            .onChange(of: router.destination) { _, destination in
                guard let destination else { return }
                switch destination {
                case .nearby: state.selectedTab = .nearby
                case .search: state.selectedTab = .search
                case .map: state.selectedTab = .map
                case .alerts: state.selectedTab = .alerts
                case .favourites: state.selectedTab = .favourites
                case .station(let id): state.routedStation = store.station(id: id)
                }
                router.consume()
            }
            .onChange(of: favoritesVM.favoriteRoutes, initial: true) { _, routes in
                disruptionsVM.updateFavoriteRoutes(routes)
            }
            .sheet(item: $state.routedStation) { station in
                NavigationStack { StationDetailView(station: station) }
            }
            .environmentObject(themeManager)
            .environmentObject(homePreferences)
            .environmentObject(favoritesVM)
            .environmentObject(recentSearches)
            .environment(\.isLowDataMode, networkMonitor.isConstrained)
            .environment(\.isLowPowerMode, energyMonitor.isLowPowerModeEnabled)
            .environment(\.isThermallyConstrained, energyMonitor.isThermallyConstrained)
            .environment(
                \.allowsContinuousAnimation,
                EnergyPolicy(
                    isLowDataMode: networkMonitor.isConstrained,
                    isLowPowerMode: energyMonitor.isLowPowerModeEnabled,
                    isThermallyConstrained: energyMonitor.isThermallyConstrained
                ).allowsContinuousAnimation
            )
    }

    private var tabs: some View {
        TabView(selection: $state.selectedTab) {
            Tab("Nearby", systemImage: "location.fill", value: .nearby) {
                NavigationStack {
                    NearbyView(
                        store: store,
                        locationManager: locationManager,
                        favoritesVM: favoritesVM,
                        disruptionsVM: disruptionsVM,
                        isActive: state.selectedTab == .nearby
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
                    MapStationsView(
                        store: store,
                        locationManager: locationManager,
                        favoritesVM: favoritesVM
                    )
                }
            }

            Tab("Alerts", systemImage: "exclamationmark.triangle.fill", value: .alerts) {
                NavigationStack {
                    DisruptionsView(vm: disruptionsVM, isActive: state.selectedTab == .alerts)
                }
            }
            .badge(disruptionsVM.relevantCount)

            Tab("Favourites", systemImage: "star.fill", value: .favourites) {
                NavigationStack {
                    FavoritesView(vm: favoritesVM, store: store, isActive: state.selectedTab == .favourites)
                }
            }
        }
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

#Preview {
    RootTabView(state: RootTabState())
}
