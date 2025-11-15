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
    
    // monitor data from API, initially we don't have it
    @Published var monitor: MonitorResponse?
    
    init(station: Station, network: NetworkManaging = NetworkManager()) {
        self.station = station
        self.network = network
    }
    
    /// Loads live monitor data for the current station's DIVA.
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
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
