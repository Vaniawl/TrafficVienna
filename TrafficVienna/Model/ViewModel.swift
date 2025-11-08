//
//  ViewModel.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 07.11.25.
//

import Foundation
import Combine

final class ViewModel: ObservableObject {
    @Published var departures: [Departure] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let network: NetworkManaging
    
    init(network: NetworkManaging = NetworkManager()) {
        self.network = network
    }
}
