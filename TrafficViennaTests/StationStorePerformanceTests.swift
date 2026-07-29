import CoreLocation
import XCTest
@testable import TrafficVienna

final class StationStorePerformanceTests: XCTestCase {
    private var store: StationStore!

    override func setUp() {
        super.setUp()
        store = StationStore()
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    func testOneHundredIndexedSearchesPerformance() {
        let queries = ["schotten", "wien", "ring", "platz", "dorf"]
        var resultCount = 0

        measure(metrics: [XCTClockMetric()], options: options) {
            for index in 0..<100 {
                resultCount += store
                    .stationsSuggestion(matching: queries[index % queries.count])
                    .count
            }
        }

        XCTAssertGreaterThan(resultCount, 0)
    }

    func testOneHundredIndexedSpatialQueriesPerformance() {
        let center = CLLocation(latitude: 48.2082, longitude: 16.3738)
        var resultCount = 0

        measure(metrics: [XCTClockMetric()], options: options) {
            for _ in 0..<100 {
                resultCount += store
                    .stations(near: center, radiusInMeters: 1_500)
                    .count
            }
        }

        XCTAssertGreaterThan(resultCount, 0)
    }

    private var options: XCTMeasureOptions {
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        return options
    }
}
