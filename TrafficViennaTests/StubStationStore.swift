import CoreLocation
@testable import TrafficVienna

final class StubStationStore: StationStoring {
    var stations: [Station]
    var loadState: StationCatalogState
    var reloadState: StationCatalogState
    var reloadCount = 0
    var requestedQueries: [String] = []

    init(
        stations: [Station],
        loadState: StationCatalogState = .loaded,
        reloadState: StationCatalogState = .loaded
    ) {
        self.stations = stations
        self.loadState = loadState
        self.reloadState = reloadState
    }

    func diva(forExact name: String) -> Int? {
        stations.first { $0.name == name }?.diva
    }

    func stationsSuggestion(matching query: String) -> [Station] {
        requestedQueries.append(query)
        return stations.filter { $0.name.localizedStandardContains(query) }
    }

    func reload() {
        reloadCount += 1
        loadState = reloadState
    }

    func stations(
        near location: CLLocation,
        radiusInMeters radius: Double
    ) -> [Station] {
        stations
    }
}
