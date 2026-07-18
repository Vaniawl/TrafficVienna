import CoreLocation
import XCTest
@testable import TrafficVienna

@MainActor
final class NearbyViewModelTests: XCTestCase {
    func testLoadSortsNearbyStationsAndPublishesSnapshotFreshness() async {
        let location = CLLocation(latitude: 48.2082, longitude: 16.3738)
        let updatedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let stations = [
            Station(id: 2, diva: 202, name: "Farther", lat: 48.2100, lon: 16.3738),
            Station(id: 1, diva: 101, name: "Closer", lat: 48.2083, lon: 16.3738),
        ]
        let monitor = NearbyMonitorProvider(updatedAt: updatedAt, isStale: true)
        let viewModel = NearbyViewModel(
            store: NearbyStationStore(stations: stations),
            location: NearbyLocationProvider(userLocation: location),
            service: monitor
        )

        await viewModel.load(force: true)
        let requestedDivas = await monitor.requestedDivas

        XCTAssertEqual(viewModel.items.map(\.id), [1, 2])
        XCTAssertTrue(viewModel.items.allSatisfy(\.isStale))
        XCTAssertTrue(viewModel.items.allSatisfy { $0.updatedAt == updatedAt })
        XCTAssertTrue(viewModel.items.allSatisfy { !$0.lines.isEmpty })
        XCTAssertEqual(requestedDivas, [101, 202])
    }

    func testLoadWithoutLocationClearsItemsWithoutRequestingNetwork() async {
        let monitor = NearbyMonitorProvider()
        let viewModel = NearbyViewModel(
            store: NearbyStationStore(stations: [
                Station(id: 1, diva: 101, name: "Test", lat: 48.2083, lon: 16.3738),
            ]),
            location: NearbyLocationProvider(userLocation: nil),
            service: monitor
        )

        await viewModel.load()
        let requestedDivas = await monitor.requestedDivas

        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertTrue(requestedDivas.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isRefreshing)
    }
}

@MainActor
private final class NearbyLocationProvider: LocationProviding {
    let userLocation: CLLocation?

    init(userLocation: CLLocation?) {
        self.userLocation = userLocation
    }
}

@MainActor
private final class NearbyStationStore: StationStoring {
    let stations: [Station]
    let loadState: StationCatalogState = .loaded

    init(stations: [Station]) {
        self.stations = stations
    }

    func diva(forExact name: String) -> Int? {
        stations.first { $0.name == name }?.diva
    }

    func stationsSuggestion(matching query: String) -> [Station] {
        stations.filter { $0.name.localizedStandardContains(query) }
    }

    func reload() {}

    func stations(near location: CLLocation, radiusInMeters radius: Double) -> [Station] {
        stations.filter { station in
            CLLocation(latitude: station.lat, longitude: station.lon).distance(from: location) <= radius
        }
    }
}

private actor NearbyMonitorProvider: MonitorProviding {
    private(set) var requestedDivas: [Int] = []
    private let updatedAt: Date
    private let isStale: Bool

    init(updatedAt: Date = .now, isStale: Bool = false) {
        self.updatedAt = updatedAt
        self.isStale = isStale
    }

    func monitor(diva: Int, forceRefresh: Bool) async throws -> MonitorResponse {
        try await monitorSnapshot(diva: diva, forceRefresh: forceRefresh).response
    }

    func monitorSnapshot(diva: Int, forceRefresh: Bool) async throws -> MonitorSnapshot {
        requestedDivas.append(diva)
        let line = Lines(
            name: "U1",
            towards: "Leopoldau",
            departures: Departures(departure: [
                Departure(departureTime: DepartureTime(countdown: 3, timePlanned: nil, timeReal: nil)),
            ])
        )
        let stop = LocationStop(
            properties: Properties(title: "Test", attributes: Attributes(rbl: diva)),
            geometry: nil
        )
        return MonitorSnapshot(
            response: MonitorResponse(
                data: DataBlock(monitors: [Monitor(locationStop: stop, lines: [line])], trafficInfos: nil)
            ),
            updatedAt: updatedAt,
            isStale: isStale
        )
    }
}
