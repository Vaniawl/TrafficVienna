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
    func station(id: Int) -> Station?
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
    private var stationsByID: [Int: Station] = [:]
    private var searchIndex: [(station: Station, normalizedName: String, words: [String])] = []
    private var divaByNormalizedName: [String: Int] = [:]
    private var spatialIndex: [SpatialCell: [Station]] = [:]

    private struct SpatialCell: Hashable {
        let latitude: Int
        let longitude: Int
    }

    private static let spatialCellSize = 0.01
    
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
            stationsByID = Dictionary(uniqueKeysWithValues: decoded.map { ($0.id, $0) })
            searchIndex = decoded
                .map { station in
                    let name = normalize(station.name)
                    return (station, name, name.split(separator: " ").map(String.init))
                }
                .sorted {
                    ($0.normalizedName, $0.station.id) < ($1.normalizedName, $1.station.id)
                }
            divaByNormalizedName = decoded.reduce(into: [:]) { index, station in
                guard let diva = station.diva else { return }
                index[normalize(station.name), default: diva] = diva
            }
            spatialIndex = Dictionary(grouping: decoded, by: spatialCell(for:))
            log.debug("Loaded \(decoded.count) stations")
        } catch {
            log.error("Failed to load stations: \(error, privacy: .public)")
        }
    }
    
    // Returns the DIVA number for a station whose normalized name
    // matches the provided name exactly
    func diva(forExact name: String) -> Int? {
        divaByNormalizedName[normalize(name)]
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
        
        var ranked = Array(repeating: [Station](), count: 4)
        for entry in searchIndex {
            guard entry.normalizedName.contains(q) else { continue }
            if entry.normalizedName == q {
                ranked[0].append(entry.station)
            } else if entry.normalizedName.hasPrefix(q) {
                ranked[1].append(entry.station)
            } else if entry.words.contains(where: { $0.hasPrefix(q) }) {
                ranked[2].append(entry.station)
            } else {
                ranked[3].append(entry.station)
            }
        }
        return ranked.flatMap { $0 }
    }

    func station(id: Int) -> Station? { stationsByID[id] }
    
    // for nearby stations
    func stations(
        near location: CLLocation,
        radiusInMeters radius: Double
    ) -> [Station] {
        let center = spatialCell(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let cellRadius = max(1, Int(ceil(radius / 700)))
        let candidates = (-cellRadius...cellRadius).flatMap { latitudeOffset in
            (-cellRadius...cellRadius).flatMap { longitudeOffset in
                spatialIndex[SpatialCell(latitude: center.latitude + latitudeOffset, longitude: center.longitude + longitudeOffset)] ?? []
            }
        }
        return candidates.filter { station in
            let stationLocation = CLLocation(
                latitude: station.lat,
                longitude: station.lon
            )
            return stationLocation.distance(from: location) <= radius
        }
    }

    private func spatialCell(for station: Station) -> SpatialCell {
        spatialCell(latitude: station.lat, longitude: station.lon)
    }

    private func spatialCell(latitude: Double, longitude: Double) -> SpatialCell {
        SpatialCell(
            latitude: Int(floor(latitude / Self.spatialCellSize)),
            longitude: Int(floor(longitude / Self.spatialCellSize))
        )
    }
}
