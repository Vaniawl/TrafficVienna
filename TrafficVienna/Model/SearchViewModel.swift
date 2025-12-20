//
//  SearchViewModel.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 16.12.25.
//

import Foundation
import Combine

final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    
    private let store: StationStore
    private let locationManager: LocationManager
    
    var nearbyStations: [Station] {
        guard let location = locationManager.userLocation else { return [] }
        return store.stations(near: location, maxDistance: 500)
    }
    
    var suggestions: [Station] {
        guard !query.isEmpty else { return [] }
        return store.stationsSuggestion(matching: query)
    }
    
    init(store: StationStore, locationManager: LocationManager) {
        self.store = store
        self.locationManager = locationManager
    }
    

}
