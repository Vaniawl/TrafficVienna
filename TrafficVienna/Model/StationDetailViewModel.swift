//
//  StationDetailViewModel.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 13.11.25.
//

import Foundation
import Combine

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
    
    @MainActor
    func load() async {
        print("➡️ StationDetailViewModel.load() called")

        errorMessage = nil
        isLoading = true
        
        defer { isLoading = false
            print("⬅️ StationDetailViewModel.load() finished")
}
        
        guard let diva = station.diva else {
            print("❌ No DIVA for station \(station.name)")

            errorMessage = "No DIVA for this station"
            return
        }
        print("🎯 Loading monitor for DIVA \(diva)")

        do {
            let response = try await network.fetchMonitorData(diva: diva, includeArea: true)
            print("✅ Monitor response received")

            self.monitor = response
        } catch {
            print("🔥 Failed to load monitor:", error)

            errorMessage = error.localizedDescription
        }
    }
}
