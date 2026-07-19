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

nonisolated private let log = Logger(subsystem: "at.wellbe.TrafficVienna", category: "store")

nonisolated struct Station: Decodable, Identifiable, Sendable {
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
    func station(diva: Int) -> Station?
    func stations(
        near location: CLLocation,
        radiusInMeters radius: Double
    ) -> [Station]    // finds stations in radius
}

// Loads the bundled station dataset and builds indexes used by search and map views.
final class StationStore: ObservableObject, StationStoring {
    // All stations from the Wiener Linien JSON
    @Published private(set) var stations: [Station] = []
    @Published private(set) var isReady = false
    private var stationsByID: [Int: Station] = [:]
    private var stationsByDiva: [Int: Station] = [:]
    private var searchIndex: [SearchEntry] = []
    private var searchBigramIndex: [String: [Int]] = [:]
    private var divaByNormalizedName: [String: Int] = [:]
    private var spatialIndex: [SpatialCell: [Station]] = [:]
    private var loadingTask: Task<Void, Never>?

    nonisolated private struct SpatialCell: Hashable, Sendable {
        let latitude: Int
        let longitude: Int
    }

    nonisolated private struct SearchEntry: Sendable {
        let station: Station
        let normalizedName: String
        let words: [String]
    }

    nonisolated private struct Snapshot: Sendable {
        let stations: [Station]
        let stationsByID: [Int: Station]
        let stationsByDiva: [Int: Station]
        let searchIndex: [SearchEntry]
        let searchBigramIndex: [String: [Int]]
        let divaByNormalizedName: [String: Int]
        let spatialIndex: [SpatialCell: [Station]]
    }

    nonisolated private static let spatialCellSize = 0.01

    init(loadSynchronously: Bool = true) {
        guard let url = Bundle.main.url(
            forResource: "wienerlinien-ogd-haltestellen",
            withExtension: "json"
        ) else {
            log.error("JSON file NOT FOUND")
            isReady = true
            return
        }

        if loadSynchronously {
            apply(Self.loadSnapshot(from: url))
        } else {
            loadingTask = Task { [weak self] in
                let snapshot = await Task.detached(priority: .userInitiated) {
                    Self.loadSnapshot(from: url)
                }.value
                self?.apply(snapshot)
            }
        }
    }

    nonisolated private static func loadSnapshot(from url: URL) -> Snapshot? {
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([Station].self, from: data)
            let searchIndex = decoded
                .map { station in
                    let name = normalize(station.name)
                    return SearchEntry(
                        station: station,
                        normalizedName: name,
                        words: name.split(separator: " ").map(String.init)
                    )
                }
                .sorted {
                    ($0.normalizedName, $0.station.id) < ($1.normalizedName, $1.station.id)
                }
            let divaByNormalizedName = decoded.reduce(into: [String: Int]()) { index, station in
                guard let diva = station.diva else { return }
                index[normalize(station.name), default: diva] = diva
            }
            var searchBigramIndex: [String: [Int]] = [:]
            for (index, entry) in searchIndex.enumerated() {
                for bigram in Set(bigrams(in: entry.normalizedName)) {
                    searchBigramIndex[bigram, default: []].append(index)
                }
            }
            let stationsByDiva = decoded.reduce(into: [Int: Station]()) { index, station in
                guard let diva = station.diva else { return }
                if let existing = index[diva], existing.id <= station.id { return }
                index[diva] = station
            }
            return Snapshot(
                stations: decoded,
                stationsByID: Dictionary(uniqueKeysWithValues: decoded.map { ($0.id, $0) }),
                stationsByDiva: stationsByDiva,
                searchIndex: searchIndex,
                searchBigramIndex: searchBigramIndex,
                divaByNormalizedName: divaByNormalizedName,
                spatialIndex: Dictionary(grouping: decoded, by: spatialCell(for:))
            )
        } catch {
            log.error("Failed to load stations: \(error, privacy: .public)")
            return nil
        }
    }

    private func apply(_ snapshot: Snapshot?) {
        if let snapshot {
            stationsByID = snapshot.stationsByID
            stationsByDiva = snapshot.stationsByDiva
            searchIndex = snapshot.searchIndex
            searchBigramIndex = snapshot.searchBigramIndex
            divaByNormalizedName = snapshot.divaByNormalizedName
            spatialIndex = snapshot.spatialIndex
            stations = snapshot.stations
            log.debug("Loaded \(snapshot.stations.count) stations")
        }
        isReady = true
        loadingTask = nil
    }

    func waitUntilReady() async {
        await loadingTask?.value
    }

    // Returns the DIVA number for a station whose normalized name
    // matches the provided name exactly
    func diva(forExact name: String) -> Int? {
        divaByNormalizedName[Self.normalize(name)]
    }

    // Normalizes a string for station name matching
    nonisolated private static func normalize(_ s: String) -> String {
        s.folding(options: .diacriticInsensitive, locale: .current)
         .replacingOccurrences(of: "ß", with: "ss")
         .lowercased()
         .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Returns stations that roughly match the query by name
    func stationsSuggestion(matching query: String) -> [Station] {
        let q = Self.normalize(query)

        guard !q.isEmpty else { return [] }

        var ranked = Array(repeating: [Station](), count: 4)
        for entry in searchCandidates(for: q) {
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

    func indexedCandidateCount(matching query: String) -> Int {
        let normalized = Self.normalize(query)
        guard !normalized.isEmpty else { return 0 }
        return searchCandidates(for: normalized).count
    }

    private func searchCandidates(for normalizedQuery: String) -> [SearchEntry] {
        guard let firstBigram = Self.bigrams(in: normalizedQuery).first else { return searchIndex }
        return searchBigramIndex[firstBigram, default: []].map { searchIndex[$0] }
    }

    func station(id: Int) -> Station? { stationsByID[id] }

    func station(diva: Int) -> Station? { stationsByDiva[diva] }

    // for nearby stations
    func stations(
        near location: CLLocation,
        radiusInMeters radius: Double
    ) -> [Station] {
        let center = Self.spatialCell(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
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

    nonisolated private static func spatialCell(for station: Station) -> SpatialCell {
        spatialCell(latitude: station.lat, longitude: station.lon)
    }

    nonisolated private static func bigrams(in value: String) -> [String] {
        let characters = Array(value)
        guard characters.count >= 2 else { return [] }
        return (0..<(characters.count - 1)).map { String(characters[$0...($0 + 1)]) }
    }

    nonisolated private static func spatialCell(latitude: Double, longitude: Double) -> SpatialCell {
        SpatialCell(
            latitude: Int(floor(latitude / Self.spatialCellSize)),
            longitude: Int(floor(longitude / Self.spatialCellSize))
        )
    }
}
