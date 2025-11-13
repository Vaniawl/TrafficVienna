//
//  TrafficViennaTests.swift
//  TrafficViennaTests
//
//  Created by Ivan Dovhosheia on 10.11.25.
//

import XCTest
@testable import TrafficVienna

final class TrafficViennaTests: XCTestCase {

    func testLoadStationsNotEmpty() {
        // Given
        let store = StationStore()
        
        // Then
        XCTAssertGreaterThan(store.stations.count, 0, "StationStore should load stations from bundled JSON")
    }

}
