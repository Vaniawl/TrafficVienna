import CoreLocation
import MapKit
import SwiftUI

struct NearbyView: View {
    @StateObject private var vm: NearbyViewModel
    @ObservedObject private var locationManager: LocationManager
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.openURL) private var openURL
    @State private var showAccount = false

    init(store: StationStore, locationManager: LocationManager) {
        _vm = StateObject(wrappedValue: NearbyViewModel(store: store, location: locationManager))
        _locationManager = ObservedObject(wrappedValue: locationManager)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [themeManager.preset.accentColor.opacity(0.14), Color(.systemGroupedBackground), Color(.systemGroupedBackground)],
                startPoint: .topLeading,
                endPoint: .center
            )
            .ignoresSafeArea()

            switch locationManager.authorizationStatus {
            case .denied, .restricted:
                stateScreen(icon: "location.slash.fill", eyebrow: "LOCATION REQUIRED", title: "Vienna is waiting", subtitle: "Turn on location to discover live departures and stations around you.", action: ("Open Settings", openSettings))
            case .notDetermined:
                stateScreen(icon: "location.fill", eyebrow: "START YOUR JOURNEY", title: "What’s moving nearby?", subtitle: "See every tram, bus and train around you — live and in one place.", action: ("Use my location", locationManager.requestLocationIfNeeded))
            default:
                if !vm.hasLocation {
                    stateScreen(icon: "location.circle.fill", eyebrow: "LOCATING", title: "Finding your place in Vienna", subtitle: "This will only take a moment.", showsProgress: true)
                } else if vm.items.isEmpty && !vm.isLoading {
                    stateScreen(icon: "tram.fill", eyebrow: "NO STOPS FOUND", title: "Nothing within 500 m", subtitle: "Move a little closer to a station and refresh the results.")
                } else {
                    stationList
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showAccount) { AccountView() }
        .task {
            while !Task.isCancelled {
                await vm.load(force: false)
                try? await Task.sleep(for: .seconds(vm.items.isEmpty ? 5 : 60))
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "tram.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(themeManager.preset.accentColor, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("TRAFFIC").font(.caption2.bold()).tracking(1.8)
                        Text("VIENNA").font(.caption2.bold()).tracking(1.8).foregroundStyle(themeManager.preset.accentColor)
                    }
                }
                Spacer()
                themeMenu
                Button { showAccount = true } label: {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.title2)
                        .frame(width: 42, height: 42)
                        .background(.thinMaterial, in: Circle())
                }
                .accessibilityLabel("Account")
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(greeting).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                Text("Move through Vienna\nwithout the guesswork.")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .tracking(-0.7)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var themeMenu: some View {
        Menu {
            ForEach(ThemePreset.allCases) { preset in
                Button {
                    ThemeManager.shared.preset = preset
                } label: {
                    Label(preset.displayName, systemImage: ThemeManager.shared.preset == preset ? "checkmark.circle.fill" : "circle")
                }
            }
        } label: {
            Image(systemName: "paintpalette.fill")
                .frame(width: 42, height: 42)
                .background(.thinMaterial, in: Circle())
        }
        .accessibilityLabel("Change theme")
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let period = hour < 12 ? "Good morning" : (hour < 18 ? "Good afternoon" : "Good evening")
        return "\(period) · Live city departures"
    }

    private func stateScreen(icon: String, eyebrow: String, title: String, subtitle: String, action: (title: String, perform: () -> Void)? = nil, showsProgress: Bool = false) -> some View {
        ScrollView {
            VStack(spacing: 26) {
                header
                VStack(alignment: .leading, spacing: 24) {
                    HStack(alignment: .top) {
                        Image(systemName: icon)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 68, height: 68)
                            .background(themeManager.preset.accentColor.gradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        Spacer()
                        Text("LIVE")
                            .font(.caption2.bold()).tracking(1.5)
                            .foregroundStyle(themeManager.preset.accentColor)
                            .padding(.horizontal, 10).padding(.vertical, 7)
                            .background(themeManager.preset.accentColor.opacity(0.1), in: Capsule())
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(eyebrow).font(.caption.bold()).tracking(1.4).foregroundStyle(themeManager.preset.accentColor)
                        Text(title).font(.title2.bold())
                        Text(subtitle).font(.body).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                    if showsProgress { ProgressView().tint(themeManager.preset.accentColor) }
                    if let action {
                        Button(action: action.perform) {
                            HStack {
                                Text(action.title).fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                            .padding(.horizontal, 18).frame(height: 54)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.white)
                        .background(themeManager.preset.accentColor, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                    }
                }
                .padding(22)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay { RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(.white.opacity(0.55)) }
                .shadow(color: .black.opacity(0.08), radius: 24, y: 14)
                .padding(.horizontal, 20)

                HStack(spacing: 0) {
                    metric("5", "transport modes")
                    Divider().frame(height: 36)
                    metric("24/7", "live updates")
                    Divider().frame(height: 36)
                    metric("500 m", "nearby radius")
                }
                .padding(.vertical, 16)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 30)
        }
    }

    private func metric(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.subheadline.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var stationList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                header
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("AROUND YOU").font(.caption2.bold()).tracking(1.4).foregroundStyle(themeManager.preset.accentColor)
                        Text("Next departures").font(.title2.bold())
                    }
                    Spacer()
                    Button { Task { await vm.load(force: true) } } label: {
                        if vm.isRefreshing { ProgressView().controlSize(.small) } else { Image(systemName: "arrow.clockwise") }
                    }
                    .frame(width: 42, height: 42)
                    .background(.thinMaterial, in: Circle())
                    .disabled(vm.isRefreshing)
                }
                .padding(.horizontal, 20).padding(.top, 8)

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
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 20)
        }
        .refreshable { await vm.load(force: true) }
    }

    private func openInMaps(_ station: Station) {
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: station.lat, longitude: station.lon))
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = station.name
        mapItem.openInMaps()
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
    }
}

#Preview {
    NavigationStack { NearbyView(store: StationStore(), locationManager: LocationManager()) }
        .environmentObject(ThemeManager.shared)
        .environmentObject(AuthStore())
}
