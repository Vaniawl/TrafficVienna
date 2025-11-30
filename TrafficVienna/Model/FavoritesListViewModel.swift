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
    
    func load() {
        let routes = FavoritesManager.all()
        guard !routes.isEmpty else {
            items = []
            return
        }
        Task {
            var result: [FavoriteWithDeparture] = []
            
            for fav in routes {
                if let item = await loadItem(for: fav) {
                    result.append(item)
                }
            }
            await MainActor.run {
                self.items = result
            }
        }
    }
    
    private func loadItem(for fav: FavoriteRoute) async -> FavoriteWithDeparture? {
        guard let divaInt = Int(fav.diva) else { return nil}
        do {
            //to pull data from api(station)
            let response = try await network.fetchMonitorData(diva: divaInt, includeArea: true)
            
            guard let monitor = response.data.monitors.first else { return nil }
            
            guard let line = monitor.lines.first(where: {
                $0.name == fav.lineName && $0.towards == fav.destination
            }) else { return nil }
            
            
            let departures: [DepartureInfo] = line.departures.departure.map { dep in
                let time = dep.departureTime
                
                return DepartureInfo(
                    countdown: time.countdown,
                    planned: time.timePlanned,
                    real: time.timeReal,
                    isRealtime: time.timeReal != nil
                )
               
            }
            return FavoriteWithDeparture(route: fav, departures: departures)
        } catch {
            print("Failed to load favorite \(fav): \(error)")
            return nil

        }
        
    }

}
