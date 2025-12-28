//
//  StationDetailViewModel.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 13.11.25.
//

import Foundation
import Combine

/// ViewModel responsible for loading and exposing live monitor data
/// for a single station selected from the search screen.

final class StationDetailViewModel: ObservableObject {
    // station that user selected from search
    let station: Station
    
    // network layer for loading monitor data
    private let network: NetworkManaging
    
    // loading state for the view
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var favorites: Set<FavoriteRoute> = []
    
    // monitor data from API, initially we don't have it
    @Published var monitor: MonitorResponse?
    
    init(station: Station, network: NetworkManaging = NetworkManager()) {
        self.station = station
        self.network = network
    }
    
    // Loads live monitor data for the current station's DIVA.
    @MainActor
    func load() async {
        errorMessage = nil
        isLoading = true
        
        defer { isLoading = false }
        // a station without DIVA cannot be used to load monitor data
        guard let diva = station.diva else {
            errorMessage = "No DIVA for this station"
            return
        }

        do {
            // perform the network request and decode the response
            let response = try await network.fetchMonitorData(diva: diva, includeArea: true)
            self.monitor = response
            if let widgetData = widgetData(from: response) {
                WidgetSync.save([widgetData])
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
    }
    
        //MARK: this functions will be removed (favorites)
    func loadFavourites() {
        favorites = Set(FavoritesManager.all())
    }
    
    func isFavorite (line: Lines) -> Bool {
        guard let divaInt = station.diva else { return false }
        let diva = String(divaInt)
        
        let fav = FavoriteRoute(diva: diva, lineName: line.name, destination: line.towards)
        
        return favorites.contains(fav)
    }
    
    func toggleFavorite(line: Lines) {
        guard let divaInt = station.diva else { return }
        let diva = String(divaInt)
        
        FavoritesManager.toggle(diva: diva, lineName: line.name, destination: line.towards)
        loadFavourites()
    }
    
    private func widgetData(from response: MonitorResponse) -> WidgetDepartureData? {
        guard let monitor = response.data.monitors.first else {
            return nil
        }
        guard let line = monitor.lines.first else {
            return nil
        }
        let lineName = line.name
        let stopName = monitor.locationStop.properties.title
        let destination = line.towards
        let allDepartures = line.departures.departure
        let minutes = allDepartures.map { $0.departureTime.countdown }
        let nextThree = Array(minutes.prefix(3))
        
        return WidgetDepartureData(
            lineName: lineName, stopName: stopName, destination: destination, departures: nextThree
        )
    }
}
