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

private enum Tab: String { case nearby, search, map, alerts, favourites }

struct RootTabView: View {
    @StateObject private var store = StationStore()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var favoritesVM = FavoritesListViewModel()
    @StateObject private var disruptionsVM = DisruptionsViewModel()
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var themeManager = ThemeManager.shared
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var selectedTab: Tab = .nearby

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
                withAnimation { selectedTab = Tab(rawValue: type) ?? .nearby }
            }
            .environmentObject(themeManager)
    }

    private var tabs: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                NearbyView(store: store, locationManager: locationManager)
            }
            .tabItem { Label("Nearby", systemImage: "location.fill") }
            .tag(Tab.nearby)

            NavigationStack {
                SearchView(store: store)
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }
            .tag(Tab.search)

            NavigationStack {
                MapStationsView(store: store, locationManager: locationManager)
            }
            .tabItem { Label("Map", systemImage: "map.fill") }
            .tag(Tab.map)

            NavigationStack {
                DisruptionsView(vm: disruptionsVM)
            }
            .tabItem { Label("Alerts", systemImage: "exclamationmark.triangle.fill") }
            .badge(disruptionsVM.infos.count)
            .tag(Tab.alerts)

            NavigationStack {
                FavoritesView(vm: favoritesVM)
            }
            .tabItem { Label("Favourites", systemImage: "star.fill") }
            .tag(Tab.favourites)
        }
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

#Preview {
    RootTabView()
}
