import CoreLocation

struct MapRefreshContext: Hashable {
    let catalogState: StationCatalogState
    let authorizationRawValue: Int32
    let latitude: Double?
    let longitude: Double?
    let locationError: String?

    init(
        catalogState: StationCatalogState,
        authorizationStatus: CLAuthorizationStatus,
        location: CLLocation?,
        locationError: String?
    ) {
        self.catalogState = catalogState
        authorizationRawValue = authorizationStatus.rawValue
        latitude = location?.coordinate.latitude
        longitude = location?.coordinate.longitude
        self.locationError = locationError
    }
}
