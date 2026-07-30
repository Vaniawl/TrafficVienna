import CoreLocation
import XCTest
@testable import TrafficVienna

@MainActor
final class LocationManagerTests: XCTestCase {
    func testAuthorizedRequestUsesOneShotLocationAndCoalescesDuplicates() {
        let service = LocationServiceSpy(authorizationStatus: .authorizedWhenInUse)
        let locationManager = LocationManager(manager: service)

        locationManager.requestLocationIfNeeded()
        locationManager.requestLocationIfNeeded()

        XCTAssertEqual(service.requestLocationCount, 1)
        XCTAssertEqual(service.authorizationRequestCount, 0)
        XCTAssertEqual(service.desiredAccuracy, kCLLocationAccuracyNearestTenMeters)
    }

    func testUndeterminedRequestAsksForPermissionBeforeLocation() {
        let service = LocationServiceSpy(authorizationStatus: .notDetermined)
        let locationManager = LocationManager(manager: service)

        locationManager.requestLocationIfNeeded()

        XCTAssertEqual(service.authorizationRequestCount, 1)
        XCTAssertEqual(service.requestLocationCount, 0)
    }

    func testCompletedLocationAllowsAUserInitiatedRefresh() {
        let service = LocationServiceSpy(authorizationStatus: .authorizedWhenInUse)
        let locationManager = LocationManager(manager: service)
        locationManager.requestLocationIfNeeded()

        locationManager.locationManager(
            CLLocationManager(),
            didUpdateLocations: [
                CLLocation(latitude: 48.2082, longitude: 16.3738),
            ]
        )
        locationManager.requestLocationIfNeeded()

        XCTAssertEqual(service.requestLocationCount, 2)
        XCTAssertEqual(locationManager.userLocation?.coordinate.latitude, 48.2082)
    }

    func testTemporaryLocationFailureAllowsRetry() {
        let service = LocationServiceSpy(authorizationStatus: .authorizedWhenInUse)
        let locationManager = LocationManager(manager: service)
        locationManager.requestLocationIfNeeded()

        locationManager.locationManager(
            CLLocationManager(),
            didFailWithError: CLError(.locationUnknown)
        )
        locationManager.requestLocationIfNeeded()

        XCTAssertEqual(service.requestLocationCount, 2)
        XCTAssertNil(locationManager.errorMessage)
    }

    func testEmptyLocationUpdateAllowsRetry() {
        let service = LocationServiceSpy(authorizationStatus: .authorizedWhenInUse)
        let locationManager = LocationManager(manager: service)
        locationManager.requestLocationIfNeeded()

        locationManager.locationManager(
            CLLocationManager(),
            didUpdateLocations: []
        )
        locationManager.requestLocationIfNeeded()

        XCTAssertEqual(service.requestLocationCount, 2)
    }
}

@MainActor
private final class LocationServiceSpy: LocationManaging {
    weak var delegate: (any CLLocationManagerDelegate)?
    var desiredAccuracy = kCLLocationAccuracyThreeKilometers
    let authorizationStatus: CLAuthorizationStatus
    private(set) var authorizationRequestCount = 0
    private(set) var requestLocationCount = 0

    init(authorizationStatus: CLAuthorizationStatus) {
        self.authorizationStatus = authorizationStatus
    }

    func requestWhenInUseAuthorization() {
        authorizationRequestCount += 1
    }

    func requestLocation() {
        requestLocationCount += 1
    }
}
