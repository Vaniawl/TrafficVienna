//
//  NearbyStationsViewModel.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 06.01.26.
//

import Foundation
import Combine

final class NearbyStationsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lines: [Lines] = []
    @Published var lastUpdated: Date?

    private let station: Station
    private let network: NetworkManaging
    

    init(station: Station, network: NetworkManaging = NetworkManager()) {
        self.station = station
        self.network = network
    }

    var lastUpdatedText: String? {
        guard let lastUpdated = lastUpdated else { return nil }
        
        let seconds = Int(Date().timeIntervalSince(lastUpdated))
        
        if seconds < 30 {
            return "now"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes) ago"
        } else {
            let hours = seconds / 3600
            return "\(hours) ago"
        }
    }
    
    @MainActor
    func load() async {
        guard let diva = station.diva else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await network.fetchMonitorData(diva: diva, includeArea: true)
            // Collect all lines from all platforms at this station
            self.lines = response.data.monitors.flatMap { $0.lines }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    
}
