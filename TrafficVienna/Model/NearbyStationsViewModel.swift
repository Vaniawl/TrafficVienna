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

    private let station: Station
    private let network: NetworkManaging

    init(station: Station, network: NetworkManaging = NetworkManager()) {
        self.station = station
        self.network = network
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
