//
//  FavoritesListViewModel.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 29.11.25.
//

import Foundation
import SwiftUI
import Combine


struct DepartureInfo: Identifiable, Hashable {
    let id = UUID()
    let countdown: Int
    let planned: String
    let real: String?
    let isRealtime: Bool
}

struct FavoriteWithDeparture: Identifiable {
    let id = UUID()
    let route: FavoriteRoute
    let departures: [DepartureInfo]
}

@MainActor
final class FavoritesListViewModel: ObservableObject {
    //what the view will render
    @Published var items: [FavoriteWithDeparture] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let network: NetworkManaging
    private let favoritesRepo: FavoritesRepository
    private let widgetSync: WidgetSyncing

    init(
        network: NetworkManaging,
        favoritesRepo: FavoritesRepository,
        widgetSync: WidgetSyncing = WidgetSyncManager()
    ) {
        self.network = network
        self.favoritesRepo = favoritesRepo
        self.widgetSync = widgetSync
    }

    convenience init(
        network: NetworkManaging = NetworkManager(),
        favoritesRepo: FavoritesRepository = UserDefaultsFavoritesRepository()
    ) {
        self.init(
            network: network,
            favoritesRepo: favoritesRepo,
            widgetSync: WidgetSyncManager()
        )
    }
    
    func loadFavorites() {
        let routes = favoritesRepo.getAll()
        
        guard !routes.isEmpty else {
            items = []
            syncWidget()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            var result: [FavoriteWithDeparture] = []
            
            for route in routes {
                let item = await loadItem(for: route)
                result.append(item)
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
            
            self.items = result
            self.isLoading = false
            self.syncWidget()
        }
    }
    
    
    func refresh(_ route: FavoriteRoute) {
        Task {
            let updated = await loadItem(for: route)
            
            guard let index = items.firstIndex(where: {
                $0.route.diva == route.diva &&
                $0.route.lineName == route.lineName &&
                $0.route.destination == route.destination
            }) else { return }
            
            items[index] = updated
            syncWidget()
        }
    }

    func removeAll() {
        favoritesRepo.removeAll()
        items = []
        syncWidget()
    }
    
    private func loadItem(for favorite: FavoriteRoute) async -> FavoriteWithDeparture {
        guard let divaInt = Int(favorite.diva) else {
            print("⚠️ Invalid DIVA: \(favorite.diva)")
            return FavoriteWithDeparture(route: favorite, departures: [])
        }
        
        do {
            let response = try await network.fetchMonitorData(diva: divaInt, includeArea: true)
            let monitors = response.data.monitors
            
            guard !monitors.isEmpty else {
                print("⚠️ No monitors for DIVA \(divaInt)")
                return FavoriteWithDeparture(route: favorite, departures: [])
            }
            
            // Знаходимо потрібну лінію
            guard let line = findMatchingLine(in: monitors, for: favorite) else {
                print("⚠️ No matching line for \(favorite.lineName) -> \(favorite.destination)")
                return FavoriteWithDeparture(route: favorite, departures: [])
            }
            
            // Конвертуємо відправлення
            let departures = mapDepartures(from: line)
            
            print("✅ Loaded \(favorite.lineName) -> \(favorite.destination), departures: \(departures.count)")
            return FavoriteWithDeparture(route: favorite, departures: departures)
            
        } catch {
            print("❌ Failed to load favorite \(favorite): \(error)")
            return FavoriteWithDeparture(route: favorite, departures: [])
        }
    }
    
    //finds line that matches favorite
    private func findMatchingLine(in monitors: [Monitor], for favorite: FavoriteRoute) -> Lines? {
        monitors
            .flatMap { $0.lines }
            .first { line in
                line.name == favorite.lineName &&
                normalize(line.towards) == normalize(favorite.destination)
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
                    planned: time.timePlanned,
                    real: time.timeReal,
                    isRealtime: time.timeReal != nil
                )
            }
    }
    
    private func normalize(_ string: String) -> String {
        string
            .replacingOccurrences(of: " U", with: "")
            .replacingOccurrences(of: " S", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    
    private func syncWidget() {
        //takes first 3 lines
        let topFavorites = items.prefix(3)
        
        let widgetItems: [WidgetDepartureData] = topFavorites.map { favorite in
            WidgetDepartureData(
                lineName: favorite.route.lineName,
                stopName: favorite.route.diva,
                destination: favorite.route.destination,
                departures: favorite.departures.prefix(3).map { $0.countdown }
            )
        }
        
        widgetSync.save(widgetItems)
    }
}
