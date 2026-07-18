import CoreLocation
import Observation

@MainActor
@Observable
final class MapStationsViewModel {
    private(set) var contentState: MapContentState = .loading
    private(set) var locationStatus: MapLocationStatus = .permissionNeeded
    private(set) var visibleStations: [Station] = []

    private let stationStore: StationStoring
    private let fallbackLocation: CLLocation
    private let radius: Double
    private let markerLimit: Int

    init(
        stationStore: StationStoring,
        fallbackLocation: CLLocation? = nil,
        radius: Double = 1_500,
        markerLimit: Int = 60
    ) {
        self.stationStore = stationStore
        self.fallbackLocation = fallbackLocation ?? CLLocation(
            latitude: 48.2082,
            longitude: 16.3738
        )
        self.radius = radius
        self.markerLimit = markerLimit
    }

    func refresh(
        location: CLLocation?,
        authorizationStatus: CLAuthorizationStatus,
        locationError: String?
    ) {
        locationStatus = Self.locationStatus(
            location: location,
            authorizationStatus: authorizationStatus,
            hasError: locationError != nil
        )

        switch stationStore.loadState {
        case .loading:
            visibleStations = []
            contentState = .loading
            return
        case .failed:
            visibleStations = []
            contentState = .unavailable
            return
        case .loaded:
            break
        }

        let center = location ?? fallbackLocation
        visibleStations = stationStore
            .stations(near: center, radiusInMeters: radius)
            .map { station in
                (
                    station: station,
                    distance: CLLocation(
                        latitude: station.lat,
                        longitude: station.lon
                    ).distance(from: center)
                )
            }
            .sorted { $0.distance < $1.distance }
            .prefix(markerLimit)
            .map(\.station)
        contentState = visibleStations.isEmpty ? .empty : .ready
    }

    func retry(
        location: CLLocation?,
        authorizationStatus: CLAuthorizationStatus,
        locationError: String?
    ) {
        stationStore.reload()
        refresh(
            location: location,
            authorizationStatus: authorizationStatus,
            locationError: locationError
        )
    }

    private static func locationStatus(
        location: CLLocation?,
        authorizationStatus: CLAuthorizationStatus,
        hasError: Bool
    ) -> MapLocationStatus {
        if location != nil {
            return .located
        }

        switch authorizationStatus {
        case .notDetermined:
            return .permissionNeeded
        case .denied, .restricted:
            return .permissionDenied
        case .authorizedAlways, .authorizedWhenInUse:
            return hasError ? .fallback : .locating
        @unknown default:
            return .fallback
        }
    }
}
