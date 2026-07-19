//
//  FavoritesListViewModel.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 29.11.25.
//

import Foundation
import Combine
import SwiftUI
import OSLog

private let log = Logger(subsystem: "at.wellbe.TrafficVienna", category: "favorites")


struct DepartureInfo: Identifiable, Hashable {
    let countdown: Int
    let planned: String
    let real: String?
    let isRealtime: Bool

    var id: String { "\(planned)|\(real ?? "")|\(countdown)" }
}

struct FavoriteWithDeparture: Identifiable {
    let route: FavoriteRoute
    let stopName: String
    let departures: [DepartureInfo]
    var freshness: DataFreshness = .network(.now)
    var loadError: String? = nil

    var id: FavoriteRoute { route }
}

@MainActor
final class FavoritesListViewModel: ObservableObject {
    //what the view will render
    @Published var items: [FavoriteWithDeparture] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var stations: [FavoriteStation] = []
    @Published private(set) var favoriteRoutes: [FavoriteRoute] = []

    private let service: MonitorService
    private let favoritesRepo: FavoritesRepository
    private let stationsRepo: FavoriteStationsStoring
    private let widgetSync: WidgetSyncing
    private var loadGeneration = 0

    init(
        service: MonitorService,
        favoritesRepo: FavoritesRepository,
        stationsRepo: FavoriteStationsStoring = UserDefaultsFavoriteStationsRepository(),
        widgetSync: WidgetSyncing = WidgetSyncManager()
    ) {
        self.service = service
        self.favoritesRepo = favoritesRepo
        self.stationsRepo = stationsRepo
        self.widgetSync = widgetSync
        self.stations = stationsRepo.all()
        self.favoriteRoutes = favoritesRepo.getAll()
    }

    convenience init(
        service: MonitorService = .shared,
        favoritesRepo: FavoritesRepository = UserDefaultsFavoritesRepository()
    ) {
        self.init(
            service: service,
            favoritesRepo: favoritesRepo,
            stationsRepo: UserDefaultsFavoriteStationsRepository(),
            widgetSync: WidgetSyncManager()
        )
    }

    // MARK: - Favourite stations (local, ordered)

    func loadStations() {
        stations = stationsRepo.all()
    }

    func isStationFavorite(id: Int) -> Bool {
        stations.contains { $0.id == id }
    }

    func toggleStation(_ station: Station) {
        let favorite = FavoriteStation(station)
        stationsRepo.toggle(favorite)
        if let index = stations.firstIndex(where: { $0.id == station.id }) {
            stations.remove(at: index)
        } else {
            stations.append(favorite)
        }
    }

    func removeStation(id: Int) {
        stationsRepo.remove(id: id)
        stations.removeAll { $0.id == id }
    }

    func removeStations(at offsets: IndexSet) {
        let ids = offsets.compactMap { stations.indices.contains($0) ? stations[$0].id : nil }
        guard !ids.isEmpty else { return }
        ids.forEach { stationsRepo.remove(id: $0) }
        let removedIDs = Set(ids)
        stations.removeAll { removedIDs.contains($0.id) }
    }

    func moveStations(fromOffsets: IndexSet, toOffset: Int) {
        stations.move(fromOffsets: fromOffsets, toOffset: toOffset)
        stationsRepo.setOrder(stations)
    }

    func moveFavoriteRoutes(fromOffsets: IndexSet, toOffset: Int) {
        invalidateLoads()
        favoriteRoutes.move(fromOffsets: fromOffsets, toOffset: toOffset)
        favoritesRepo.setOrder(favoriteRoutes)
        let itemsByRoute = Dictionary(uniqueKeysWithValues: items.map { ($0.route, $0) })
        items = favoriteRoutes.compactMap { itemsByRoute[$0] }
        syncWidget()
    }

    var isEmpty: Bool {
        favoriteRoutes.isEmpty && stations.isEmpty
    }

    func isLineFavorite(diva: Int?, lineName: String, destination: String) -> Bool {
        guard let diva else { return false }
        return favoriteRoutes.contains(
            FavoriteRoute(diva: String(diva), lineName: lineName, destination: destination)
        )
    }

    func toggleLineFavorite(diva: Int?, lineName: String, destination: String) {
        guard let diva else { return }
        invalidateLoads()
        let route = FavoriteRoute(diva: String(diva), lineName: lineName, destination: destination)
        favoritesRepo.toggle(diva: route.diva, lineName: lineName, destination: destination)
        if let index = favoriteRoutes.firstIndex(of: route) {
            favoriteRoutes.remove(at: index)
            items.removeAll { $0.route == route }
        } else {
            favoriteRoutes.append(route)
        }
    }

    var staleMessage: String? {
        for item in items {
            if case let .stale(_, message) = item.freshness { return message }
        }
        return nil
    }
    
    func loadFavorites(forceRefresh: Bool = false) async {
        guard forceRefresh || !isLoading else { return }
        loadGeneration &+= 1
        let generation = loadGeneration
        let routes = favoriteRoutes
        
        guard !routes.isEmpty else {
            items = []
            syncWidget()
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer {
            if generation == loadGeneration { isLoading = false }
        }

        let previousItems = Dictionary(uniqueKeysWithValues: items.map { ($0.route, $0) })
        var result = Array<FavoriteWithDeparture?>(repeating: nil, count: routes.count)
        await withTaskGroup(of: (Int, FavoriteWithDeparture).self) { group in
            for (index, route) in routes.enumerated() {
                group.addTask { @MainActor in
                    (
                        index,
                        await self.loadItem(
                            for: route,
                            forceRefresh: forceRefresh,
                            fallback: previousItems[route]
                        )
                    )
                }
            }

            for await (index, item) in group {
                guard !Task.isCancelled else {
                    group.cancelAll()
                    return
                }
                result[index] = item
            }
        }

        guard !Task.isCancelled, generation == loadGeneration else { return }
        items = result.compactMap { $0 }
        syncWidget()
    }
    
    
    func refresh(_ route: FavoriteRoute) {
        Task {
            let fallback = items.first { $0.route == route }
            let updated = await loadItem(for: route, forceRefresh: true, fallback: fallback)
            
            guard let index = items.firstIndex(where: {
                $0.route.diva == route.diva &&
                $0.route.lineName == route.lineName &&
                $0.route.destination == route.destination
            }) else { return }
            
            items[index] = updated
            syncWidget()
        }
    }

    func remove(_ route: FavoriteRoute) {
        invalidateLoads()
        // toggle() removes an existing favourite.
        favoritesRepo.toggle(
            diva: route.diva,
            lineName: route.lineName,
            destination: route.destination
        )
        favoriteRoutes.removeAll { $0 == route }
        items.removeAll { $0.route == route }
        syncWidget()
    }

    func removeFavoriteRoutes(at offsets: IndexSet) {
        let routes = offsets.compactMap {
            favoriteRoutes.indices.contains($0) ? favoriteRoutes[$0] : nil
        }
        guard !routes.isEmpty else { return }
        invalidateLoads()
        let removedRoutes = Set(routes)
        favoriteRoutes.removeAll { removedRoutes.contains($0) }
        items.removeAll { removedRoutes.contains($0.route) }
        favoritesRepo.setOrder(favoriteRoutes)
        syncWidget()
    }

    func removeAll() {
        invalidateLoads()
        favoritesRepo.removeAll()
        favoriteRoutes = []
        items = []
        syncWidget()
    }

    func clearTravelFavorites() {
        invalidateLoads()
        favoritesRepo.removeAll()
        stationsRepo.removeAll()
        favoriteRoutes = []
        stations = []
        items = []
        widgetSync.clear()
    }

    func replaceTravelFavorites(stations: [FavoriteStation], routes: [FavoriteRoute]) {
        invalidateLoads()
        stationsRepo.setOrder(stations)
        favoritesRepo.setOrder(routes)
        self.stations = stations
        favoriteRoutes = routes
        items = []
        errorMessage = nil
        widgetSync.clear()
    }

    private func invalidateLoads() {
        loadGeneration &+= 1
        isLoading = false
    }
    
    private func loadItem(
        for favorite: FavoriteRoute,
        forceRefresh: Bool = false,
        fallback: FavoriteWithDeparture? = nil
    ) async -> FavoriteWithDeparture {
        guard let divaInt = Int(favorite.diva) else {
            log.warning("Invalid DIVA: \(favorite.diva, privacy: .public)")
            return FavoriteWithDeparture(route: favorite, stopName: "", departures: [])
        }

        do {
            let result = try await service.monitorResult(diva: divaInt, forceRefresh: forceRefresh)
            let monitors = result.value.data.monitors

            guard !monitors.isEmpty else {
                log.warning("No monitors for DIVA \(divaInt)")
                return FavoriteWithDeparture(route: favorite, stopName: "", departures: [])
            }

            guard let line = findMatchingLine(in: monitors, for: favorite) else {
                log.warning("No matching line for \(favorite.lineName, privacy: .public) -> \(favorite.destination, privacy: .public)")
                return FavoriteWithDeparture(route: favorite, stopName: "", departures: [])
            }

            let stopName = monitors.first?.locationStop.properties.title ?? ""
            let departures = mapDepartures(from: line)

            log.debug("Loaded \(favorite.lineName, privacy: .public) -> \(favorite.destination, privacy: .public), departures: \(departures.count)")
            return FavoriteWithDeparture(route: favorite, stopName: stopName, departures: departures, freshness: result.freshness)

        } catch {
            log.error("Failed to load favorite \(favorite.lineName, privacy: .public): \(error, privacy: .public)")
            if let fallback {
                return FavoriteWithDeparture(
                    route: favorite,
                    stopName: fallback.stopName,
                    departures: fallback.departures,
                    freshness: fallback.freshness,
                    loadError: error.monitorDisplayMessage
                )
            }
            return FavoriteWithDeparture(
                route: favorite,
                stopName: "",
                departures: [],
                loadError: error.monitorDisplayMessage
            )
        }
    }
    
    private func findMatchingLine(in monitors: [Monitor], for favorite: FavoriteRoute) -> Lines? {
        monitors
            .flatMap { $0.lines }
            .first { line in
                RouteMatching.matches(
                    lineName: line.name, towards: line.towards,
                    favoriteLine: favorite.lineName, favoriteDestination: favorite.destination
                )
            }
    }
    
    //to show next departures
    private func mapDepartures(from line: Lines) -> [DepartureInfo] {
        line.departures.departure
            .prefix(7)
            .map { departure in
                let time = departure.departureTime
                return DepartureInfo(
                    countdown: time.countdown,
                    planned: time.timePlanned ?? "",
                    real: time.timeReal,
                    isRealtime: time.timeReal != nil
                )
            }
    }
    

    private func syncWidget() {
        //takes first 3 lines
        let topFavorites = items.prefix(3)
        
        let widgetItems: [WidgetDepartureData] = topFavorites.map { favorite in
            WidgetDepartureData(
                lineName: favorite.route.lineName,
                stopName: favorite.stopName,
                destination: favorite.route.destination,
                departures: favorite.departures.prefix(3).map { $0.countdown }
            )
        }
        
        widgetSync.save(widgetItems)
    }
}
