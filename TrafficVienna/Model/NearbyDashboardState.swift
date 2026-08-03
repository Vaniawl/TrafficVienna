import CoreLocation

enum NearbyDashboardState: Equatable {
    case locationDenied
    case permissionRequired
    case locating
    case locationUnavailable
    case noStations
    case stations

    init(
        authorizationStatus: CLAuthorizationStatus,
        hasLocation: Bool,
        hasStations: Bool,
        hasLocationError: Bool = false
    ) {
        switch authorizationStatus {
        case .denied, .restricted:
            self = .locationDenied
        case .notDetermined:
            self = .permissionRequired
        case .authorizedAlways, .authorizedWhenInUse:
            if !hasLocation {
                self = hasLocationError ? .locationUnavailable : .locating
            } else if hasStations {
                self = .stations
            } else {
                self = .noStations
            }
        @unknown default:
            self = .locationDenied
        }
    }
}
