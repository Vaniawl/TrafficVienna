import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class FavoritesListViewModel {
    private(set) var items: [FavoriteWithDeparture] = []
    private(set) var stations: [FavoriteStation] = []
    private(set) var isLoading = false

    private let service: MonitorProviding
    private let favoritesRepo: FavoritesRepository
    private let stationsRepo: FavoriteStationsStoring
    private let widgetSync: WidgetSyncing

    init(
        service: MonitorProviding = MonitorService.shared,
        favoritesRepo: FavoritesRepository = UserDefaultsFavoritesRepository(),
        stationsRepo: FavoriteStationsStoring = UserDefaultsFavoriteStationsRepository(),
        widgetSync: WidgetSyncing = WidgetSyncManager()
    ) {
        self.service = service
        self.favoritesRepo = favoritesRepo
        self.stationsRepo = stationsRepo
        self.widgetSync = widgetSync
    }

    var isEmpty: Bool {
        items.isEmpty && stations.isEmpty
    }

    func loadStations() {
        stations = stationsRepo.all()
    }

    func removeStation(id: Int) {
        stationsRepo.remove(id: id)
        loadStations()
    }

    func moveStations(fromOffsets: IndexSet, toOffset: Int) {
        stations.move(fromOffsets: fromOffsets, toOffset: toOffset)
        stationsRepo.setOrder(stations)
    }

    func loadFavorites(forceRefresh: Bool = false) async {
        guard !isLoading else { return }
        let routes = favoritesRepo.getAll().sorted()
        guard !routes.isEmpty else {
            items = []
            syncWidget()
            return
        }

        isLoading = true
        defer { isLoading = false }

        var result: [FavoriteWithDeparture] = []
        for route in routes {
            guard !Task.isCancelled else { return }
            result.append(await loadItem(for: route, forceRefresh: forceRefresh))
        }
        guard !Task.isCancelled else { return }
        items = result
        syncWidget()
    }

    func refresh(_ route: FavoriteRoute) async {
        let updated = await loadItem(for: route, forceRefresh: true)
        guard !Task.isCancelled else { return }
        guard let index = items.firstIndex(where: { $0.route == route }) else { return }
        items[index] = updated
        syncWidget()
    }

    func remove(_ route: FavoriteRoute) {
        favoritesRepo.toggle(diva: route.diva, lineName: route.lineName, destination: route.destination)
        items.removeAll { $0.route == route }
        syncWidget()
    }

    private func loadItem(
        for favorite: FavoriteRoute,
        forceRefresh: Bool
    ) async -> FavoriteWithDeparture {
        guard let diva = Int(favorite.diva) else {
            return unavailableItem(for: favorite)
        }

        do {
            let response = try await service.monitor(diva: diva, forceRefresh: forceRefresh)
            guard let line = response.data.monitors
                .flatMap(\.lines)
                .first(where: {
                    RouteMatching.matches(
                        lineName: $0.name,
                        towards: $0.towards,
                        favoriteLine: favorite.lineName,
                        favoriteDestination: favorite.destination
                    )
                }) else {
                return unavailableItem(for: favorite)
            }

            let departures = line.departures.departure.prefix(7).map { departure in
                let time = departure.departureTime
                return DepartureInfo(
                    countdown: time.countdown,
                    planned: time.timePlanned ?? "",
                    real: time.timeReal,
                    isRealtime: time.timeReal != nil
                )
            }
            return FavoriteWithDeparture(
                route: favorite,
                stopName: response.data.monitors.first?.locationStop.properties.title ?? "",
                departures: departures,
                state: .available
            )
        } catch {
            return unavailableItem(for: favorite)
        }
    }

    private func unavailableItem(for route: FavoriteRoute) -> FavoriteWithDeparture {
        FavoriteWithDeparture(route: route, stopName: "", departures: [], state: .unavailable)
    }

    private func syncWidget() {
        let widgetItems = items
            .filter { $0.state == .available }
            .prefix(3)
            .map { favorite in
                WidgetDepartureData(
                    lineName: favorite.route.lineName,
                    stopName: favorite.stopName,
                    destination: favorite.route.destination,
                    departures: favorite.departures.prefix(3).map(\.countdown)
                )
            }
        widgetSync.save(Array(widgetItems))
    }
}
