import MapKit
import SwiftUI

struct MapStationsView: View {
    @ObservedObject private var store: StationStore
    @ObservedObject private var locationManager: LocationManager
    @State private var viewModel: MapStationsViewModel
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedStation: Station?
    @State private var pendingCameraCenter: CLLocation?
    @State private var exploredCenter: CLLocation?
    @State private var searchFeedback = 0
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
                stationMarker(for: station)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .mapStyle(
            .standard(
                elevation: .flat,
                pointsOfInterest: .excludingAll,
                showsTraffic: false
            )
        )
        .accessibilityIdentifier("stations-map")
        .overlay {
            MapContentOverlay(
                state: viewModel.contentState,
                retry: retryCatalog
            )
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            pendingCameraCenter = CLLocation(
                latitude: context.region.center.latitude,
                longitude: context.region.center.longitude
            )
        }
        // Camera-driven controls must not resize the map. A changing safe-area
        // inset feeds back into MapKit's camera centre and can cause layout churn.
        .overlay(alignment: .top) {
            if canSearchThisArea || viewModel.locationStatus != .located {
                VStack(spacing: Spacing.sm) {
                    if canSearchThisArea {
                        Button(
                            "Search this area",
                            systemImage: "magnifyingglass",
                            action: searchThisArea
                        )
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(DesignColor.primaryText)
                        .controlSize(.regular)
                        .accessibilityHint("Updates stops around the centre of the map")
                        .transition(Motion.stateTransition(reduceMotion: reduceMotion))
                    }

                    if viewModel.locationStatus != .located {
                        MapLocationBannerView(
                            status: viewModel.locationStatus,
                            isExploringArea: exploredCenter != nil,
                            requestLocation: locationManager.requestLocationIfNeeded,
                            openSettings: openSettings
                        )
                    }
                }
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
                .transition(Motion.edgeTransition(.bottom, reduceMotion: reduceMotion))
            }
        }
        .sensoryFeedback(.selection, trigger: selectedStation?.id)
        .sensoryFeedback(.impact(weight: .light), trigger: searchFeedback)
        .animation(Motion.quick(reduceMotion: reduceMotion), value: selectedStation)
        .animation(Motion.quick(reduceMotion: reduceMotion), value: canSearchThisArea)
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Station.self) { station in
            StationDetailView(station: station)
        }
        .task(id: refreshContext) {
            refresh()
        }
        .background(DesignColor.background)
        .tint(DesignColor.accentText)
    }

    private func stationMarker(for station: Station) -> some MapContent {
        let coordinate = CLLocationCoordinate2D(
            latitude: station.lat,
            longitude: station.lon
        )
        return Marker(
            "Stop \(station.name)",
            systemImage: "tram.fill",
            coordinate: coordinate
        )
        .tint(.appAccent)
        .tag(station)
    }

    private var refreshContext: MapRefreshContext {
        MapRefreshContext(
            catalogState: store.loadState,
            authorizationStatus: locationManager.authorizationStatus,
            location: locationManager.userLocation,
            locationError: locationManager.errorMessage
        )
    }

    private var canSearchThisArea: Bool {
        guard position.positionedByUser,
              let pendingCameraCenter
        else {
            return false
        }
        return viewModel.shouldOfferSearch(at: pendingCameraCenter)
    }

    private func refresh() {
        viewModel.refresh(
            location: locationManager.userLocation,
            authorizationStatus: locationManager.authorizationStatus,
            locationError: locationManager.errorMessage,
            mapCenter: exploredCenter
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
            locationError: locationManager.errorMessage,
            mapCenter: exploredCenter
        )
    }

    private func searchThisArea() {
        guard let pendingCameraCenter else { return }
        exploredCenter = pendingCameraCenter
        selectedStation = nil
        refresh()
        searchFeedback += 1
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
