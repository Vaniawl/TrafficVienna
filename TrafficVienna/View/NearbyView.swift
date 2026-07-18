import CoreLocation
import MapKit
import SwiftUI

struct NearbyView: View {
    @StateObject private var vm: NearbyViewModel
    @ObservedObject private var locationManager: LocationManager
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var routines: CommuteRoutineStore
    @ObservedObject private var favoritesVM: FavoritesListViewModel
    @ObservedObject private var disruptionsVM: DisruptionsViewModel
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase
    private let store: StationStore
    private let isActive: Bool
    @State private var showAccount = false

    init(
        store: StationStore,
        locationManager: LocationManager,
        favoritesVM: FavoritesListViewModel? = nil,
        disruptionsVM: DisruptionsViewModel? = nil,
        isActive: Bool = true
    ) {
        self.store = store
        self.isActive = isActive
        _vm = StateObject(wrappedValue: NearbyViewModel(store: store, location: locationManager))
        _locationManager = ObservedObject(wrappedValue: locationManager)
        _favoritesVM = ObservedObject(wrappedValue: favoritesVM ?? FavoritesListViewModel())
        _disruptionsVM = ObservedObject(wrappedValue: disruptionsVM ?? DisruptionsViewModel())
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            content
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showAccount) { AccountView() }
        .task(id: shouldPoll) {
            guard shouldPoll else { return }
            favoritesVM.loadStations()
            async let favoriteLoad: Void = favoritesVM.loadFavorites()
            async let alertLoad: Void = disruptionsVM.load()
            _ = await (favoriteLoad, alertLoad)
            while !Task.isCancelled {
                await vm.load(force: false)
                try? await Task.sleep(for: .seconds(vm.items.isEmpty ? 5 : 60))
            }
        }
    }

    private var shouldPoll: Bool { isActive && scenePhase == .active }

    @ViewBuilder
    private var content: some View {
        switch locationManager.authorizationStatus {
        case .denied, .restricted:
            dashboard(state: .locationOff)
        case .notDetermined:
            dashboard(state: .permission)
        default:
            if !vm.hasLocation {
                dashboard(state: .locating)
            } else if vm.items.isEmpty && !vm.isLoading {
                dashboard(state: .empty)
            } else {
                departuresDashboard
            }
        }
    }

    private var topBar: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) {
                    HStack { accountAvatar; Spacer(); refreshButton }
                    accountTitle
                }
            } else {
                HStack(spacing: 12) {
                    accountAvatar
                    accountTitle
                    Spacer()
                    refreshButton
                }
            }
        }
    }

    private var accountAvatar: some View {
            Button { showAccount = true } label: {
                Text(initials)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black, in: Circle())
            }
            .accessibilityLabel("Account")
    }

    private var accountTitle: some View {
            VStack(alignment: .leading, spacing: 1) {
                Text(greeting).font(.caption).foregroundStyle(.secondary)
                Text(auth.session?.displayName ?? "Traffic Vienna")
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
            }
    }

    private var refreshButton: some View {
            Button { Task { await vm.load(force: true) } } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(Color(.secondarySystemGroupedBackground), in: Circle())
            }
            .disabled(vm.isRefreshing)
            .accessibilityLabel("Refresh departures")
    }

    private func dashboard(state: DashboardState) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                topBar
                heroCard(state)
                quickActions
                insightCard
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
    }

    private func heroCard(_ state: DashboardState) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("VIENNA LIVE", systemImage: "wave.3.right")
                    .font(.caption2.bold()).tracking(1.2)
                Spacer()
                Text(state.badge)
                    .font(.caption.bold())
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.white.opacity(0.18), in: Capsule())
            }

            Spacer(minLength: 34)

            Image(systemName: state.icon)
                .font(.system(size: 30, weight: .semibold))
                .frame(width: 60, height: 60)
                .background(.white.opacity(0.18), in: Circle())

            Spacer(minLength: 22)

            Text(state.title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .tracking(-0.7)
            Text(state.subtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))
                .padding(.top, 8)
                .fixedSize(horizontal: false, vertical: true)

            if state.showsProgress {
                ProgressView().tint(.white).padding(.top, 20)
            } else if let actionTitle = state.actionTitle {
                Button {
                    state.perform(using: locationManager, openSettings: openSettings)
                } label: {
                    HStack {
                                Text(actionTitle).fontWeight(.semibold).lineLimit(2)
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 18).padding(.vertical, 13)
                    .frame(minHeight: 52)
                    .background(.white, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 24)
            }
        }
        .foregroundStyle(.white)
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: 370, alignment: .topLeading)
        .background(
            LinearGradient(colors: [Color(hex: 0x635BFF), Color(hex: 0x2F28C9), Color(hex: 0x15112E)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .shadow(color: Color(hex: 0x4338CA).opacity(0.24), radius: 24, y: 14)
    }

    private var quickActions: some View {
        HStack(alignment: .top, spacing: 0) {
            actionButton("Locate", icon: "location.fill") { locationManager.requestLocationIfNeeded() }
            NavigationLink { SearchView(store: store) } label: { actionLabel("Search", icon: "magnifyingglass") }
            NavigationLink { MapStationsView(store: store, locationManager: locationManager) } label: { actionLabel("Map", icon: "map.fill") }
            actionButton("Refresh", icon: "arrow.clockwise") { Task { await vm.load(force: true) } }
        }
        .buttonStyle(.plain)
    }

    private func actionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { actionLabel(title, icon: icon) }
    }

    private func actionLabel(_ title: String, icon: String) -> some View {
        VStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 52, height: 52)
                .background(Color(.secondarySystemGroupedBackground), in: Circle())
            Text(title).font(.caption).foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
    }

    private var insightCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "bolt.fill")
                .foregroundStyle(Color(hex: 0x635BFF))
                .frame(width: 44, height: 44)
                .background(Color(hex: 0x635BFF).opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(smartInsightTitle).font(.headline)
                Text(smartInsightSubtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var smartInsightTitle: String {
        if disruptionsVM.relevantCount > 0 { return "\(disruptionsVM.relevantCount) alert for your lines" }
        if let routine = routines.current { return "\(routine.name): \(routine.station.name)" }
        if !favoritesVM.stations.isEmpty { return "\(favoritesVM.stations.count) favourite stations ready" }
        return "Live departures"
    }

    private var smartInsightSubtitle: String {
        if disruptionsVM.relevantCount > 0 { return "Check service changes before you leave" }
        if let routine = routines.current { return "Scheduled around \(routine.hour.formatted(.number.precision(.integerLength(2)))):00" }
        return "Automatic updates every 60 seconds"
    }

    private var departuresDashboard: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                topBar.padding(.horizontal, 18)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nearby now").font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("Live departures within 500 metres").font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18).padding(.vertical, 12)
                quickActions.padding(.horizontal, 8).padding(.bottom, 8)

                ForEach(vm.items) { item in
                    NavigationLink { StationDetailView(station: item.station) } label: {
                        StationCardView(
                            station: item.station,
                            distance: item.distance,
                            lines: item.lines,
                            failed: item.failed,
                            updatedAt: item.updatedAt,
                            isStale: item.freshness?.isStale == true
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        let station = item.station
                        let repository = UserDefaultsFavoriteStationsRepository()
                        let isFavorite = repository.contains(id: station.id)
                        Button { repository.toggle(FavoriteStation(station)) } label: {
                            Label(isFavorite ? "Remove station from favourites" : "Add station to favourites", systemImage: isFavorite ? "star.slash" : "star")
                        }
                        ShareLink(item: "\(station.name) — live departures on Traffic Vienna")
                        Button { openInMaps(station) } label: { Label("Open in Maps", systemImage: "map") }
                    }
                    .padding(.horizontal, 18)
                }
            }
            .padding(.top, 12).padding(.bottom, 24)
        }
        .refreshable { await vm.load(force: true) }
    }

    private var initials: String {
        let source = auth.session?.displayName ?? auth.session?.email ?? "TV"
        let words = source.split(whereSeparator: { $0 == " " || $0 == "@" })
        return words.prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        return hour < 12
            ? String(localized: "Good morning")
            : (hour < 18 ? String(localized: "Good afternoon") : String(localized: "Good evening"))
    }

    private func openInMaps(_ station: Station) {
        let location = CLLocation(latitude: station.lat, longitude: station.lon)
        let mapItem = MKMapItem(location: location, address: nil)
        mapItem.name = station.name
        mapItem.openInMaps()
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
    }
}

private enum DashboardState {
    case permission, locationOff, locating, empty

    var badge: String {
        switch self {
        case .permission: String(localized: "SET UP")
        case .locationOff: String(localized: "OFFLINE")
        case .locating: String(localized: "CONNECTING")
        case .empty: String(localized: "NO RESULTS")
        }
    }
    var icon: String {
        switch self {
        case .permission: "location.fill"
        case .locationOff: "location.slash.fill"
        case .locating: "scope"
        case .empty: "tram.fill"
        }
    }
    var title: String {
        switch self {
        case .permission: String(localized: "Everything around you, live.")
        case .locationOff: String(localized: "Location is turned off.")
        case .locating: String(localized: "Finding nearby departures.")
        case .empty: String(localized: "No stops within 500 m.")
        }
    }
    var subtitle: String {
        switch self {
        case .permission: String(localized: "Allow location once and turn every nearby stop into a live departure board.")
        case .locationOff: String(localized: "Enable it in Settings to see nearby stops and real-time departures.")
        case .locating: String(localized: "Connecting your position to Vienna’s transport network.")
        case .empty: String(localized: "Try again from another location or open the map to explore the city.")
        }
    }
    var actionTitle: String? {
        switch self {
        case .permission: String(localized: "Enable location")
        case .locationOff: String(localized: "Open Settings")
        case .empty: nil
        case .locating: nil
        }
    }
    var showsProgress: Bool { self == .locating }

    func perform(using manager: LocationManager, openSettings: () -> Void) {
        switch self {
        case .permission: manager.requestLocationIfNeeded()
        case .locationOff: openSettings()
        case .empty: break
        case .locating: break
        }
    }
}

#Preview {
    NavigationStack { NearbyView(store: StationStore(), locationManager: LocationManager()) }
        .environmentObject(AuthStore())
        .environmentObject(CommuteRoutineStore())
}
