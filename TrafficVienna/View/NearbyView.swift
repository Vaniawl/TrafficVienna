import CoreLocation
import MapKit
import SwiftUI

struct NearbyView: View {
    @StateObject private var vm: NearbyViewModel
    @ObservedObject private var locationManager: LocationManager
    @EnvironmentObject private var auth: AuthStore
    @Environment(\.openURL) private var openURL
    private let store: StationStore
    private let isActive: Bool
    @State private var showAccount = false

    init(store: StationStore, locationManager: LocationManager, isActive: Bool = true) {
        self.store = store
        self.isActive = isActive
        _vm = StateObject(wrappedValue: NearbyViewModel(store: store, location: locationManager))
        _locationManager = ObservedObject(wrappedValue: locationManager)
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            content
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showAccount) { AccountView() }
        .task(id: isActive) {
            guard isActive else { return }
            while !Task.isCancelled {
                await vm.load(force: false)
                try? await Task.sleep(for: .seconds(vm.items.isEmpty ? 5 : 60))
            }
        }
    }

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
        HStack(spacing: 12) {
            Button { showAccount = true } label: {
                Text(initials)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black, in: Circle())
            }
            .accessibilityLabel("Account")

            VStack(alignment: .leading, spacing: 1) {
                Text(greeting).font(.caption).foregroundStyle(.secondary)
                Text(auth.session?.displayName ?? "Traffic Vienna")
                    .font(.headline)
                    .lineLimit(1)
            }
            Spacer()
            Button { Task { await vm.load(force: true) } } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(Color(.secondarySystemGroupedBackground), in: Circle())
            }
            .disabled(vm.isRefreshing)
            .accessibilityLabel("Refresh departures")
        }
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
                        Text(actionTitle).fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 18)
                    .frame(height: 52)
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
                Text("Live departures").font(.headline)
                Text("Automatic updates every 60 seconds").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
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
                        StationCardView(station: item.station, distance: item.distance, lines: item.lines, failed: item.failed, updatedAt: item.updatedAt)
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
        return hour < 12 ? "Good morning" : (hour < 18 ? "Good afternoon" : "Good evening")
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
        case .permission: "SET UP"
        case .locationOff: "OFFLINE"
        case .locating: "CONNECTING"
        case .empty: "NO RESULTS"
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
        case .permission: "Everything around you, live."
        case .locationOff: "Location is turned off."
        case .locating: "Finding nearby departures."
        case .empty: "No stops within 500 m."
        }
    }
    var subtitle: String {
        switch self {
        case .permission: "Allow location once and turn every nearby stop into a live departure board."
        case .locationOff: "Enable it in Settings to see nearby stops and real-time departures."
        case .locating: "Connecting your position to Vienna’s transport network."
        case .empty: "Try again from another location or open the map to explore the city."
        }
    }
    var actionTitle: String? {
        switch self {
        case .permission: "Enable location"
        case .locationOff: "Open Settings"
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
}
