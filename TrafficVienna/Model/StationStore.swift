//
//  StationStore.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 08.11.25.
//

import Foundation
import Combine
import CoreLocation
import OSLog

private let log = Logger(subsystem: "at.wellbe.TrafficVienna", category: "store")


// data  will be downloadedd from json file
nonisolated struct Station: Decodable, Identifiable { // describes ONE station
    let id: Int
    let diva: Int?
    let name: String
    let lat: Double
    let lon: Double
    
    enum CodingKeys: String, CodingKey {
        case id   = "HALTESTELLEN_ID"
        case diva = "DIVA"
        case name = "NAME"
        case lat  = "WGS84_LAT"
        case lon  = "WGS84_LON"
    }
}


protocol StationStoring {
    var stations: [Station] { get }     // All known stations loaded from the JSON dataset
    func diva(forExact name: String) -> Int?
    func stationsSuggestion(matching query: String) -> [Station]
    func stations(
        near location: CLLocation,
        radiusInMeters radius: Double
    ) -> [Station]    // finds stations in radius
}

// Concrete implementation that loads stations from a bundled JSON file
// and provides search helpers for the UI
final class StationStore: ObservableObject ,StationStoring {
    // All stations from the Wiener Linien JSON
    @Published private(set) var stations: [Station] = []
    
    init() {
        loadStations()
    }

    private func loadStations() {
        guard let url = Bundle.main.url(
            forResource: "wienerlinien-ogd-haltestellen",
            withExtension: "json"
        ) else {
            log.error("JSON file NOT FOUND")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([Station].self, from: data)
            stations = decoded
            log.debug("Loaded \(decoded.count) stations")
        } catch {
            log.error("Failed to load stations: \(error, privacy: .public)")
        }
    }
    
    // Returns the DIVA number for a station whose normalized name
    // matches the provided name exactly
    func diva(forExact name: String) -> Int? {
        let q = normalize(name)
        if let exact = stations.first(where: { normalize($0.name) == q }),
           let diva = exact.diva {
            return diva
        }
        return nil
    }
    
    // Normalizes a string for station name matching
    private func normalize(_ s: String) -> String {
        s.folding(options: .diacriticInsensitive, locale: .current)
         .replacingOccurrences(of: "ß", with: "ss")
         .lowercased()
         .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Returns stations that roughly match the query by name
    func stationsSuggestion(matching query: String) -> [Station] {
        let q = normalize(query)
        
        guard !q.isEmpty else { return [] }
        
        return stations.filter { station in
            normalize(station.name).contains(q)
        }
    }
    
    // for nearby stations
    func stations(
        near location: CLLocation,
        radiusInMeters radius: Double
    ) -> [Station] {
        stations.filter { station in
            let stationLocation = CLLocation(
                latitude: station.lat,
                longitude: station.lon
            )
            return stationLocation.distance(from: location) <= radius
        }
    }
}
