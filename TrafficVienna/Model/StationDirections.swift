import MapKit

enum StationDirections {
    static func isAvailable(for station: Station) -> Bool {
        CLLocationCoordinate2DIsValid(
            CLLocationCoordinate2D(latitude: station.lat, longitude: station.lon)
        ) && !(station.lat == 0 && station.lon == 0)
    }

    static func mapItem(for station: Station) -> MKMapItem {
        let location = CLLocation(latitude: station.lat, longitude: station.lon)
        let mapItem = MKMapItem(location: location, address: nil)
        mapItem.name = station.name
        return mapItem
    }

    static var walkingLaunchOptions: [String: Any] {
        [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking]
    }

    static func openWalkingDirections(to station: Station) {
        mapItem(for: station).openInMaps(launchOptions: walkingLaunchOptions)
    }
}
