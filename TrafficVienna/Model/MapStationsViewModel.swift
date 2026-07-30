import CoreLocation
import Observation

@MainActor
@Observable
final class MapStationsViewModel {
    static let viennaCenter = CLLocation(
        latitude: 48.2082,
        longitude: 16.3738
    )

    private(set) var contentState: MapContentState = .loading
    private(set) var locationStatus: MapLocationStatus = .permissionNeeded
    private(set) var visibleStations: [Station] = []
    private(set) var searchCenter: CLLocation?

    private let stationStore: StationStoring
    private let fallbackLocation: CLLocation
    private let radius: Double
    private let markerLimit: Int
    private let minimumMarkerSpacing: CLLocationDistance

    init(
        stationStore: StationStoring,
        fallbackLocation: CLLocation? = nil,
        radius: Double = 1_500,
        markerLimit: Int = 36,
        minimumMarkerSpacing: CLLocationDistance = 120
    ) {
        self.stationStore = stationStore
        self.fallbackLocation = fallbackLocation ?? Self.viennaCenter
        self.radius = radius
        self.markerLimit = markerLimit
        self.minimumMarkerSpacing = minimumMarkerSpacing
    }

    func refresh(
        location: CLLocation?,
        authorizationStatus: CLAuthorizationStatus,
        locationError: String?,
        mapCenter: CLLocation? = nil
    ) {
        locationStatus = Self.locationStatus(
            location: location,
            authorizationStatus: authorizationStatus,
            hasError: locationError != nil
        )

        switch stationStore.loadState {
        case .loading:
            visibleStations = []
            searchCenter = nil
            contentState = .loading
            return
        case .failed:
            visibleStations = []
            searchCenter = nil
            contentState = .unavailable
            return
        case .loaded:
            break
        }

        let center = mapCenter ?? location ?? fallbackLocation
        searchCenter = center
        let candidates = stationStore
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

        var selected: [
            (
                station: Station,
                location: CLLocation
            )
        ] = []
        selected.reserveCapacity(min(markerLimit, candidates.count))

        for candidate in candidates {
            guard selected.count < markerLimit else { break }
            let candidateLocation = CLLocation(
                latitude: candidate.station.lat,
                longitude: candidate.station.lon
            )
            let isFarEnough = selected.allSatisfy { current in
                candidateLocation.distance(from: current.location) >= minimumMarkerSpacing
            }
            if isFarEnough {
                selected.append(
                    (
                        station: candidate.station,
                        location: candidateLocation
                    )
                )
            }
        }

        visibleStations = selected.map(\.station)
        contentState = visibleStations.isEmpty ? .empty : .ready
    }

    func retry(
        location: CLLocation?,
        authorizationStatus: CLAuthorizationStatus,
        locationError: String?,
        mapCenter: CLLocation? = nil
    ) {
        stationStore.reload()
        refresh(
            location: location,
            authorizationStatus: authorizationStatus,
            locationError: locationError,
            mapCenter: mapCenter
        )
    }

    func shouldOfferSearch(
        at cameraCenter: CLLocation,
        minimumMovement: CLLocationDistance = 250
    ) -> Bool {
        switch contentState {
        case .ready, .empty:
            break
        case .loading, .unavailable:
            return false
        }

        guard let searchCenter else { return false }
        return cameraCenter.distance(from: searchCenter) >= minimumMovement
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
