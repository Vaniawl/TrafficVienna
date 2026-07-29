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
nonisolated struct Station: Decodable, Identifiable, Hashable, Sendable { // describes ONE station
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
    var loadState: StationCatalogState { get }
    func diva(forExact name: String) -> Int?
    func stationsSuggestion(matching query: String) -> [Station]
    func reload()
    func stations(
        near location: CLLocation,
        radiusInMeters radius: Double
    ) -> [Station]    // finds stations in radius
}

// Concrete implementation that loads stations from a bundled JSON file
// and provides search helpers for the UI
final class StationStore: ObservableObject ,StationStoring {
    private struct SpatialCell: Hashable {
        let latitude: Int
        let longitude: Int
    }

    private struct SearchEntry {
        let station: Station
        let normalizedName: String
    }

    private static let spatialCellSize = 0.01

    // All stations from the Wiener Linien JSON
    @Published private(set) var stations: [Station] = []
    @Published private(set) var loadState: StationCatalogState = .loading
    private var exactNameIndex: [String: Station] = [:]
    private var searchIndex: [SearchEntry] = []
    private var bigramIndex: [String: [Int]] = [:]
    private var spatialIndex: [SpatialCell: [Station]] = [:]
    
    init() {
        loadStations()
    }

    func reload() {
        loadStations()
    }

    private func loadStations() {
        loadState = .loading

        guard let url = Bundle.main.url(
            forResource: "wienerlinien-ogd-haltestellen",
            withExtension: "json"
        ) else {
            stations = []
            loadState = .failed
            log.error("JSON file NOT FOUND")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([Station].self, from: data)
            rebuildIndexes(for: decoded)
            stations = decoded
            loadState = .loaded
            log.debug("Loaded \(decoded.count) stations")
        } catch {
            clearIndexes()
            stations = []
            loadState = .failed
            log.error("Failed to load stations: \(error, privacy: .public)")
        }
    }
    
    // Returns the DIVA number for a station whose normalized name
    // matches the provided name exactly
    func diva(forExact name: String) -> Int? {
        exactNameIndex[normalize(name)]?.diva
    }
    
    // Normalizes a string for station name matching
    private func normalize(_ s: String) -> String {
        s.folding(options: .diacriticInsensitive, locale: .current)
         .replacing("ß", with: "ss")
         .lowercased()
         .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Returns stations that roughly match the query by name
    func stationsSuggestion(matching query: String) -> [Station] {
        let q = normalize(query)
        
        guard !q.isEmpty else { return [] }
        
        let candidateIndexes: any Sequence<Int>
        let bigrams = Self.bigrams(in: q)
        if let rarestBigram = bigrams.min(
            by: {
                bigramIndex[$0, default: []].count
                    < bigramIndex[$1, default: []].count
            }
        ) {
            guard let indexedCandidates = bigramIndex[rarestBigram] else {
                return []
            }
            candidateIndexes = indexedCandidates
        } else {
            candidateIndexes = searchIndex.indices
        }

        return candidateIndexes.compactMap { index in
            let entry = searchIndex[index]
            return entry.normalizedName.contains(q) ? entry.station : nil
        }
    }
    
    // for nearby stations
    func stations(
        near location: CLLocation,
        radiusInMeters radius: Double
    ) -> [Station] {
        guard radius >= 0 else { return [] }

        let latitudeDelta = radius / 111_000
        let longitudeScale = max(
            0.01,
            cos(location.coordinate.latitude * .pi / 180)
        )
        let longitudeDelta = radius / (111_000 * longitudeScale)
        let minimumCell = Self.spatialCell(
            latitude: location.coordinate.latitude - latitudeDelta,
            longitude: location.coordinate.longitude - longitudeDelta
        )
        let maximumCell = Self.spatialCell(
            latitude: location.coordinate.latitude + latitudeDelta,
            longitude: location.coordinate.longitude + longitudeDelta
        )

        var candidates: [Station] = []
        for latitude in minimumCell.latitude...maximumCell.latitude {
            for longitude in minimumCell.longitude...maximumCell.longitude {
                candidates.append(
                    contentsOf: spatialIndex[
                        SpatialCell(latitude: latitude, longitude: longitude),
                        default: []
                    ]
                )
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

    private func rebuildIndexes(for stations: [Station]) {
        var exactNames: [String: Station] = [:]
        var searchEntries: [SearchEntry] = []
        var bigramsByName: [String: [Int]] = [:]
        var spatialCells: [SpatialCell: [Station]] = [:]

        exactNames.reserveCapacity(stations.count)
        searchEntries.reserveCapacity(stations.count)
        spatialCells.reserveCapacity(stations.count / 2)

        for (index, station) in stations.enumerated() {
            let normalizedName = normalize(station.name)
            if exactNames[normalizedName] == nil {
                exactNames[normalizedName] = station
            }
            searchEntries.append(
                SearchEntry(station: station, normalizedName: normalizedName)
            )
            for bigram in Set(Self.bigrams(in: normalizedName)) {
                bigramsByName[bigram, default: []].append(index)
            }
            let cell = Self.spatialCell(
                latitude: station.lat,
                longitude: station.lon
            )
            spatialCells[cell, default: []].append(station)
        }

        exactNameIndex = exactNames
        searchIndex = searchEntries
        bigramIndex = bigramsByName
        spatialIndex = spatialCells
    }

    private func clearIndexes() {
        exactNameIndex = [:]
        searchIndex = []
        bigramIndex = [:]
        spatialIndex = [:]
    }

    private static func spatialCell(
        latitude: Double,
        longitude: Double
    ) -> SpatialCell {
        SpatialCell(
            latitude: Int(floor(latitude / spatialCellSize)),
            longitude: Int(floor(longitude / spatialCellSize))
        )
    }

    private static func bigrams(in string: String) -> [String] {
        let characters = Array(string)
        guard characters.count >= 2 else { return [] }

        return (0..<(characters.count - 1)).map {
            String(characters[$0...($0 + 1)])
        }
    }
}
