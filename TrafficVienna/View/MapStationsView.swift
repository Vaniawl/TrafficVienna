import MapKit
import SwiftUI

struct MapStationsView: View {
    @ObservedObject private var store: StationStore
    @ObservedObject private var locationManager: LocationManager
    @State private var viewModel: MapStationsViewModel
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedStation: Station?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL

    init(store: StationStore, locationManager: LocationManager) {
        _store = ObservedObject(wrappedValue: store)
        _locationManager = ObservedObject(wrappedValue: locationManager)
        _viewModel = State(
            initialValue: MapStationsViewModel(stationStore: store)
        )
    }

    var body: some View {
        Map(position: $position, selection: $selectedStation) {
            if locationManager.userLocation != nil {
                UserAnnotation()
            }

            ForEach(viewModel.visibleStations) { station in
                Marker(
                    station.name,
                    systemImage: "tram.fill",
                    coordinate: CLLocationCoordinate2D(
                        latitude: station.lat,
                        longitude: station.lon
                    )
                )
                .tint(.appAccent)
                .tag(station)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .overlay {
            MapContentOverlay(
                state: viewModel.contentState,
                retry: retryCatalog
            )
        }
        .safeAreaInset(edge: .top) {
            if viewModel.locationStatus != .located {
                MapLocationBannerView(
                    status: viewModel.locationStatus,
                    requestLocation: locationManager.requestLocationIfNeeded,
                    openSettings: openSettings
                )
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.xs)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let selectedStation {
                MapStationSelectionCard(
                    station: selectedStation,
                    close: clearSelection
                )
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xs)
                .transition(
                    reduceMotion
                        ? .opacity
                        : .move(edge: .bottom).combined(with: .opacity)
                )
            }
        }
        .sensoryFeedback(.selection, trigger: selectedStation?.id)
        .animation(reduceMotion ? nil : .snappy, value: selectedStation)
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Station.self) { station in
            StationDetailView(station: station)
        }
        .task(id: refreshContext) {
            refresh()
        }
        .background(DesignColor.background)
    }

    private var refreshContext: MapRefreshContext {
        MapRefreshContext(
            catalogState: store.loadState,
            authorizationStatus: locationManager.authorizationStatus,
            location: locationManager.userLocation,
            locationError: locationManager.errorMessage
        )
    }

    private func refresh() {
        viewModel.refresh(
            location: locationManager.userLocation,
            authorizationStatus: locationManager.authorizationStatus,
            locationError: locationManager.errorMessage
        )

        if let selectedStation,
           !viewModel.visibleStations.contains(selectedStation) {
            self.selectedStation = nil
        }
    }

    private func retryCatalog() {
        viewModel.retry(
            location: locationManager.userLocation,
            authorizationStatus: locationManager.authorizationStatus,
            locationError: locationManager.errorMessage
        )
    }

    private func clearSelection() {
        selectedStation = nil
    }

    private func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        openURL(settingsURL)
    }
}

#Preview {
    let locationManager = LocationManager()
    locationManager.userLocation = CLLocation(
        latitude: 48.2008,
        longitude: 16.3695
    )
    return NavigationStack {
        MapStationsView(
            store: StationStore(),
            locationManager: locationManager
        )
    }
}
