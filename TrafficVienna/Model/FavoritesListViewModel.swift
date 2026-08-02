import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class FavoritesListViewModel {
    private(set) var items: [FavoriteWithDeparture] = []
    private(set) var stations: [FavoriteStation] = []
    private(set) var isLoading = false
    private(set) var featuredDeparture: FeaturedDeparture?

    private let service: MonitorProviding
    private let favoritesRepo: FavoritesRepository
    private let stationsRepo: FavoriteStationsStoring
    private let widgetSync: WidgetSyncing
    // nil means no queued pass; false/true retain the strongest queued request.
    private var queuedReloadForceRefresh: Bool?
    // Route retries share the same owner as full reloads and coalesce by identity.
    private var queuedRouteRefreshes: Set<FavoriteRoute> = []

    private enum ReloadOperation {
        case all(forceRefresh: Bool)
        case routes(Set<FavoriteRoute>)
    }

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

    func containsStation(id: Int) -> Bool {
        stations.contains { $0.id == id }
    }

    func toggleStation(_ station: FavoriteStation) {
        stationsRepo.toggle(station)
        loadStations()
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
        await runReload(.all(forceRefresh: forceRefresh))
    }

    func refresh(_ route: FavoriteRoute) async {
        await runReload(.routes([route]))
    }

    private func runReload(_ initialOperation: ReloadOperation) async {
        guard !isLoading else {
            enqueue(initialOperation)
            return
        }

        isLoading = true
        defer {
            queuedReloadForceRefresh = nil
            queuedRouteRefreshes = []
            isLoading = false
        }

        var nextOperation: ReloadOperation? = initialOperation
        while let currentOperation = nextOperation {
            switch currentOperation {
            case let .all(forceRefresh):
                await loadFavoritesPass(forceRefresh: forceRefresh)
            case let .routes(routes):
                await refreshRoutesPass(routes)
            }
            guard !Task.isCancelled else { return }

            nextOperation = dequeueOperation()
        }
    }

    private func enqueue(_ operation: ReloadOperation) {
        switch operation {
        case let .all(forceRefresh):
            queuedReloadForceRefresh = (queuedReloadForceRefresh ?? false) || forceRefresh
        case let .routes(routes):
            queuedRouteRefreshes.formUnion(routes)
        }
    }

    private func dequeueOperation() -> ReloadOperation? {
        if let forceRefresh = queuedReloadForceRefresh {
            queuedReloadForceRefresh = nil
            if forceRefresh {
                // A forced full pass already includes every saved route retry.
                queuedRouteRefreshes = []
            }
            return .all(forceRefresh: forceRefresh)
        }

        guard !queuedRouteRefreshes.isEmpty else { return nil }
        let routes = queuedRouteRefreshes
        queuedRouteRefreshes = []
        return .routes(routes)
    }

    private func loadFavoritesPass(forceRefresh: Bool) async {
        let routes = favoritesRepo.getAll().sorted()
        guard !routes.isEmpty else {
            items = []
            updateFeaturedDeparture()
            syncWidget()
            return
        }

        var result: [FavoriteWithDeparture] = []
        for route in routes {
            guard !Task.isCancelled else { return }
            result.append(await loadItem(for: route, forceRefresh: forceRefresh))
        }
        guard !Task.isCancelled else { return }
        guard favoritesRepo.getAll().sorted() == routes else {
            queuedReloadForceRefresh = queuedReloadForceRefresh ?? false
            return
        }
        guard queuedReloadForceRefresh == nil else { return }
        items = result
        updateFeaturedDeparture()
        syncWidget()
    }

    private func refreshRoutesPass(_ routes: Set<FavoriteRoute>) async {
        let savedRoutes = Set(favoritesRepo.getAll())
        let targets = routes.intersection(savedRoutes).sorted()
        guard !targets.isEmpty else { return }

        var updates: [FavoriteRoute: FavoriteWithDeparture] = [:]
        for route in targets {
            guard !Task.isCancelled else { return }
            updates[route] = await loadItem(for: route, forceRefresh: true)
        }
        guard !Task.isCancelled else { return }
        guard queuedReloadForceRefresh == nil else { return }

        let currentRoutes = Set(favoritesRepo.getAll())
        var didUpdate = false
        for route in targets where currentRoutes.contains(route) {
            guard let index = items.firstIndex(where: { $0.route == route }),
                  let updated = updates[route]
            else { continue }
            items[index] = updated
            didUpdate = true
        }
        guard didUpdate else { return }
        updateFeaturedDeparture()
        syncWidget()
    }

    func remove(_ route: FavoriteRoute) {
        favoritesRepo.toggle(diva: route.diva, lineName: route.lineName, destination: route.destination)
        items.removeAll { $0.route == route }
        updateFeaturedDeparture()
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
            let snapshot = try await service.monitorSnapshot(diva: diva, forceRefresh: forceRefresh)
            guard let line = snapshot.response.data.monitors
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
                stopName: snapshot.response.data.monitors.first?.locationStop.properties.title ?? "",
                departures: departures,
                state: snapshot.isStale ? .cached : .available,
                updatedAt: snapshot.updatedAt
            )
        } catch {
            return unavailableItem(for: favorite)
        }
    }

    private func unavailableItem(for route: FavoriteRoute) -> FavoriteWithDeparture {
        FavoriteWithDeparture(
            route: route,
            stopName: "",
            departures: [],
            state: .unavailable,
            updatedAt: nil
        )
    }

    private func updateFeaturedDeparture() {
        featuredDeparture = items
            .filter { $0.state != .unavailable }
            .compactMap { item -> FeaturedDeparture? in
                guard let departure = item.departures
                    .filter({ $0.liveMinutes >= 0 })
                    .min(by: { $0.liveMinutes < $1.liveMinutes })
                else { return nil }

                return FeaturedDeparture(
                    route: item.route,
                    stopName: item.stopName,
                    departure: departure,
                    state: item.state
                )
            }
            .min { lhs, rhs in
                if lhs.departure.liveMinutes == rhs.departure.liveMinutes {
                    lhs.route < rhs.route
                } else {
                    lhs.departure.liveMinutes < rhs.departure.liveMinutes
                }
            }
    }

    private func syncWidget() {
        let projectionAnchor = Date.now
        let widgetItems = items
            .filter { $0.state != .unavailable }
            .prefix(3)
            .map { favorite in
                WidgetDepartureData(
                    diva: favorite.route.diva,
                    lineName: favorite.route.lineName,
                    stopName: favorite.stopName,
                    destination: favorite.route.destination,
                    departures: favorite.departures.prefix(3).map(\.liveMinutes),
                    fetchedAt: projectionAnchor,
                    dataUpdatedAt: favorite.updatedAt
                )
            }
        widgetSync.save(Array(widgetItems))
    }
}
