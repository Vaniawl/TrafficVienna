import CoreLocation
import XCTest
@testable import TrafficVienna

final class NearbyDashboardStateTests: XCTestCase {
    func testDeniedLocationKeepsTheDashboardInLocationDeniedState() async {
        let state = NearbyDashboardState(
            authorizationStatus: .denied,
            hasLocation: false,
            hasStations: false
        )

        XCTAssertEqual(state, .locationDenied)
    }

    func testUndecidedPermissionRequestsLocationWithoutPretendingToLocate() async {
        let state = NearbyDashboardState(
            authorizationStatus: .notDetermined,
            hasLocation: false,
            hasStations: false
        )

        XCTAssertEqual(state, .permissionRequired)
    }

    func testAuthorizedLocationWithoutCoordinatesShowsLocatingState() async {
        let state = NearbyDashboardState(
            authorizationStatus: .authorizedWhenInUse,
            hasLocation: false,
            hasStations: false
        )

        XCTAssertEqual(state, .locating)
    }

    func testAuthorizedLocationWithoutNearbyStationsShowsEmptyState() async {
        let state = NearbyDashboardState(
            authorizationStatus: .authorizedWhenInUse,
            hasLocation: true,
            hasStations: false
        )

        XCTAssertEqual(state, .noStations)
    }

    func testAuthorizedLocationWithStationsShowsDepartureContent() async {
        let state = NearbyDashboardState(
            authorizationStatus: .authorizedWhenInUse,
            hasLocation: true,
            hasStations: true
        )

        XCTAssertEqual(state, .stations)
    }
}
