import SwiftUI
import XCTest
@testable import TrafficVienna

@MainActor
final class RootNavigationStateTests: XCTestCase {
    func testExternalSearchOpensDiscoverRootWithoutChangingOtherStacks() {
        var state = populatedState()

        state.openExternalDestination(.search)

        XCTAssertEqual(state.selectedTab, .search)
        XCTAssertTrue(state.discoverPath.isEmpty)
        XCTAssertEqual(state.nearbyPath.count, 1)
        XCTAssertEqual(state.alertsPath.count, 1)
        XCTAssertEqual(state.favouritesPath.count, 1)
    }

    func testExternalNearbyOpensHomeRootWithoutChangingOtherStacks() {
        var state = populatedState()

        state.openExternalDestination(.nearby)

        XCTAssertEqual(state.selectedTab, .nearby)
        XCTAssertTrue(state.nearbyPath.isEmpty)
        XCTAssertEqual(state.discoverPath.count, 1)
        XCTAssertEqual(state.alertsPath.count, 1)
        XCTAssertEqual(state.favouritesPath.count, 1)
    }

    func testExternalFavouritesOpensSavedRootWithoutChangingOtherStacks() {
        var state = populatedState()

        state.openExternalDestination(.favourites)

        XCTAssertEqual(state.selectedTab, .favourites)
        XCTAssertTrue(state.favouritesPath.isEmpty)
        XCTAssertEqual(state.nearbyPath.count, 1)
        XCTAssertEqual(state.discoverPath.count, 1)
        XCTAssertEqual(state.alertsPath.count, 1)
    }

    func testExternalStationReplacesDiscoverStackWithOneCurrentStation() {
        var state = populatedState()

        state.openExternalStation(station(id: 2))

        XCTAssertEqual(state.selectedTab, .search)
        XCTAssertEqual(state.discoverPath.count, 1)
        XCTAssertEqual(state.nearbyPath.count, 1)
        XCTAssertEqual(state.alertsPath.count, 1)
        XCTAssertEqual(state.favouritesPath.count, 1)
    }

    func testMissingExternalStationStillOpensDiscoverRoot() {
        var state = populatedState()

        state.openExternalStation(nil)

        XCTAssertEqual(state.selectedTab, .search)
        XCTAssertTrue(state.discoverPath.isEmpty)
    }

    func testOrdinaryTabSelectionPreservesNavigationStacks() {
        var state = populatedState()

        state.select(.nearby)

        XCTAssertEqual(state.selectedTab, .nearby)
        XCTAssertEqual(state.nearbyPath.count, 1)
        XCTAssertEqual(state.discoverPath.count, 1)
        XCTAssertEqual(state.alertsPath.count, 1)
        XCTAssertEqual(state.favouritesPath.count, 1)
    }

    private func populatedState() -> RootNavigationState {
        var state = RootNavigationState()
        let station = station(id: 1)
        state.nearbyPath.append(station)
        state.discoverPath.append(station)
        state.alertsPath.append("alert")
        state.favouritesPath.append(station)
        return state
    }

    private func station(id: Int) -> Station {
        Station(
            id: id,
            diva: id,
            name: "Station \(id)",
            lat: 48.2082,
            lon: 16.3738
        )
    }
}
