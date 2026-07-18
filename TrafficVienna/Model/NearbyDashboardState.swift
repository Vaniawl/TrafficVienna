import CoreLocation

enum NearbyDashboardState: Equatable {
    case locationDenied
    case permissionRequired
    case locating
    case noStations
    case stations

    init(
        authorizationStatus: CLAuthorizationStatus,
        hasLocation: Bool,
        hasStations: Bool
    ) {
        switch authorizationStatus {
        case .denied, .restricted:
            self = .locationDenied
        case .notDetermined:
            self = .permissionRequired
        default:
            if !hasLocation {
                self = .locating
            } else if hasStations {
                self = .stations
            } else {
                self = .noStations
            }
        }
    }
}
