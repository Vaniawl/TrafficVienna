import MapKit

enum StationDirections {
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
