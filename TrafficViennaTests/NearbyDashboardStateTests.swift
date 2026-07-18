import CoreLocation
import XCTest
@testable import TrafficVienna

final class NearbyDashboardStateTests: XCTestCase {
    func testDeniedLocationKeepsTheDashboardInLocationDeniedState() {
        let state = NearbyDashboardState(
            authorizationStatus: .denied,
            hasLocation: false,
            hasStations: false
        )

        XCTAssertEqual(state, .locationDenied)
    }

    func testUndecidedPermissionRequestsLocationWithoutPretendingToLocate() {
        let state = NearbyDashboardState(
            authorizationStatus: .notDetermined,
            hasLocation: false,
            hasStations: false
        )

        XCTAssertEqual(state, .permissionRequired)
    }

    func testAuthorizedLocationWithoutCoordinatesShowsLocatingState() {
        let state = NearbyDashboardState(
            authorizationStatus: .authorizedWhenInUse,
            hasLocation: false,
            hasStations: false
        )

        XCTAssertEqual(state, .locating)
    }

    func testAuthorizedLocationWithoutNearbyStationsShowsEmptyState() {
        let state = NearbyDashboardState(
            authorizationStatus: .authorizedWhenInUse,
            hasLocation: true,
            hasStations: false
        )

        XCTAssertEqual(state, .noStations)
    }

    func testAuthorizedLocationWithStationsShowsDepartureContent() {
        let state = NearbyDashboardState(
            authorizationStatus: .authorizedWhenInUse,
            hasLocation: true,
            hasStations: true
        )

        XCTAssertEqual(state, .stations)
    }
}
