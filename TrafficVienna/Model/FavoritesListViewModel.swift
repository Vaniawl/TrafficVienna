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

final class FavoritesListViewModel: ObservableObject {
    //what the view will render
    @Published var items: [FavoriteWithDeparture] = []
    
    private let network: NetworkManaging
    
    init(network: NetworkManaging = NetworkManager()) {
        self.network = network
    }
    
    func loadFavorites() {
        let routes = FavoritesManager.all()
        guard !routes.isEmpty else {
            items = []
            return
        }
        Task {
            var result: [FavoriteWithDeparture] = []
            
            for fav in routes {
                let item = await loadItem(for: fav)
                result.append(item)
                
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
            await MainActor.run {
                self.items = result
            }
        }
    }
    
    private func loadItem(for fav: FavoriteRoute) async -> FavoriteWithDeparture {
        guard let divaInt = Int(fav.diva) else {
            return FavoriteWithDeparture(route: fav, departures: [])
        }
        do {
            //to pull data from api(station)
            let response = try await network.fetchMonitorData(diva: divaInt, includeArea: true)
            let monitors = response.data.monitors
            
            guard !monitors.isEmpty else {
                print("⚠️ no monitors for diva \(divaInt)")
                return FavoriteWithDeparture(route: fav, departures: [])
            }
            
            func normalize(_ s: String) -> String {
                s
                    .replacingOccurrences(of: " U", with: "")
                    .replacingOccurrences(of: " S", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
            }
            
            
            guard let line = monitors
                .flatMap({ $0.lines })
                .first(where: { line in
                    line.name == fav.lineName &&
                    normalize(line.towards) == normalize(fav.destination)
                }) else {
                    print("⚠️ no line for fav \(fav) on diva \(divaInt)")
                    return FavoriteWithDeparture(route: fav, departures: [])
                }
            
            
            let departures: [DepartureInfo] = line.departures.departure.prefix(7).map { dep in
                let time = dep.departureTime
                
                return DepartureInfo(
                    countdown: time.countdown,
                    planned: time.timePlanned,
                    real: time.timeReal,
                    isRealtime: time.timeReal != nil
                )
            }
            print("✅ loaded fav \(fav.lineName) -> \(fav.destination), departures: \(departures.count)")

            return FavoriteWithDeparture(route: fav, departures: departures)
        } catch {
            print("❌ Failed to load favorite \(fav): \(error)")
            return FavoriteWithDeparture(route: fav, departures: [])
        }
    }
    func removeAll() {
        FavoritesManager.removeAll()
        items = []
    }
}
