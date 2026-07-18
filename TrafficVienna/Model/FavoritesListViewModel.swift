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

    private let service: MonitorService
    private let favoritesRepo: FavoritesRepository
    private let stationsRepo: FavoriteStationsStoring
    private let widgetSync: WidgetSyncing

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

    func moveStations(fromOffsets: IndexSet, toOffset: Int) {
        stations.move(fromOffsets: fromOffsets, toOffset: toOffset)
        stationsRepo.setOrder(stations)
    }

    var isEmpty: Bool {
        items.isEmpty && stations.isEmpty
    }

    var staleMessage: String? {
        for item in items {
            if case let .stale(_, message) = item.freshness { return message }
        }
        return nil
    }
    
    func loadFavorites() async {
        let routes = favoritesRepo.getAll()
        
        guard !routes.isEmpty else {
            items = []
            syncWidget()
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        var result: [FavoriteWithDeparture] = []
        for route in routes {
            guard !Task.isCancelled else { return }
            let item = await loadItem(for: route)
            result.append(item)
        }
        
        items = result
        syncWidget()
    }
    
    
    func refresh(_ route: FavoriteRoute) {
        Task {
            let updated = await loadItem(for: route, forceRefresh: true)
            
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
        // toggle() removes an existing favourite.
        favoritesRepo.toggle(
            diva: route.diva,
            lineName: route.lineName,
            destination: route.destination
        )
        items.removeAll { $0.route == route }
        syncWidget()
    }

    func removeAll() {
        favoritesRepo.removeAll()
        items = []
        syncWidget()
    }
    
    private func loadItem(for favorite: FavoriteRoute, forceRefresh: Bool = false) async -> FavoriteWithDeparture {
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
