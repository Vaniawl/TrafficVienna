import CoreLocation
import XCTest
@testable import TrafficVienna

@MainActor
final class MapStationsViewModelTests: XCTestCase {
    func testLoadedCatalogueSortsNearestStationsAndAppliesMarkerLimit() {
        let store = StubStationStore(stations: sampleStations)
        let viewModel = makeViewModel(
            stationStore: store,
            markerLimit: 2
        )

        viewModel.refresh(
            location: nil,
            authorizationStatus: .notDetermined,
            locationError: nil
        )

        XCTAssertEqual(viewModel.contentState, .ready)
        XCTAssertEqual(viewModel.visibleStations.map(\.id), [2, 3])
    }

    func testCurrentLocationReordersVisibleStations() {
        let viewModel = makeViewModel(
            stationStore: StubStationStore(stations: sampleStations)
        )
        let currentLocation = CLLocation(latitude: 48.22, longitude: 16.39)

        viewModel.refresh(
            location: currentLocation,
            authorizationStatus: .authorizedWhenInUse,
            locationError: nil
        )

        XCTAssertEqual(viewModel.visibleStations.first?.id, 1)
        XCTAssertEqual(viewModel.locationStatus, .located)
    }

    func testLoadingCatalogueShowsLoadingState() {
        let viewModel = makeViewModel(
            stationStore: StubStationStore(
                stations: [],
                loadState: .loading
            )
        )

        viewModel.refresh(
            location: nil,
            authorizationStatus: .notDetermined,
            locationError: nil
        )

        XCTAssertEqual(viewModel.contentState, .loading)
        XCTAssertTrue(viewModel.visibleStations.isEmpty)
    }

    func testFailedCatalogueShowsUnavailableAndRetryReloads() {
        let store = StubStationStore(
            stations: sampleStations,
            loadState: .failed,
            reloadState: .loaded
        )
        let viewModel = makeViewModel(stationStore: store)

        viewModel.refresh(
            location: nil,
            authorizationStatus: .notDetermined,
            locationError: nil
        )
        XCTAssertEqual(viewModel.contentState, .unavailable)

        viewModel.retry(
            location: nil,
            authorizationStatus: .notDetermined,
            locationError: nil
        )

        XCTAssertEqual(store.reloadCount, 1)
        XCTAssertEqual(viewModel.contentState, .ready)
        XCTAssertFalse(viewModel.visibleStations.isEmpty)
    }

    func testLoadedCatalogueWithoutStationsShowsEmptyState() {
        let viewModel = makeViewModel(
            stationStore: StubStationStore(stations: [])
        )

        viewModel.refresh(
            location: nil,
            authorizationStatus: .notDetermined,
            locationError: nil
        )

        XCTAssertEqual(viewModel.contentState, .empty)
    }

    func testLocationPermissionStatesAreExplicit() {
        let viewModel = makeViewModel(
            stationStore: StubStationStore(stations: sampleStations)
        )

        viewModel.refresh(
            location: nil,
            authorizationStatus: .notDetermined,
            locationError: nil
        )
        XCTAssertEqual(viewModel.locationStatus, .permissionNeeded)

        viewModel.refresh(
            location: nil,
            authorizationStatus: .denied,
            locationError: nil
        )
        XCTAssertEqual(viewModel.locationStatus, .permissionDenied)

        viewModel.refresh(
            location: nil,
            authorizationStatus: .authorizedWhenInUse,
            locationError: nil
        )
        XCTAssertEqual(viewModel.locationStatus, .locating)

        viewModel.refresh(
            location: nil,
            authorizationStatus: .authorizedWhenInUse,
            locationError: "Location unavailable"
        )
        XCTAssertEqual(viewModel.locationStatus, .fallback)
    }

    private func makeViewModel(
        stationStore: StationStoring,
        markerLimit: Int = 60
    ) -> MapStationsViewModel {
        MapStationsViewModel(
            stationStore: stationStore,
            fallbackLocation: CLLocation(
                latitude: 48.2082,
                longitude: 16.3738
            ),
            radius: 10_000,
            markerLimit: markerLimit
        )
    }

    private var sampleStations: [Station] {
        [
            Station(
                id: 1,
                diva: 60201040,
                name: "Praterstern",
                lat: 48.2181,
                lon: 16.3915
            ),
            Station(
                id: 2,
                diva: 60200195,
                name: "Stephansplatz",
                lat: 48.2083,
                lon: 16.3731
            ),
            Station(
                id: 3,
                diva: 60200644,
                name: "Karlsplatz",
                lat: 48.2003,
                lon: 16.3695
            )
        ]
    }
}
