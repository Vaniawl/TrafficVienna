import CoreLocation

@MainActor
protocol LocationProviding: AnyObject {
    var userLocation: CLLocation? { get }
}

extension LocationManager: LocationProviding {}
