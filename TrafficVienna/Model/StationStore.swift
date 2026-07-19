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

nonisolated struct StationDistance: Sendable {
    let station: Station
    let meters: CLLocationDistance
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
        stationSuggestions(matching: query, limit: nil)
    }

    // Keeps the same ranking as the complete search while bounding result
    // storage for screens that can render only a fixed number of suggestions.
    func stationsSuggestion(matching query: String, limit: Int) -> [Station] {
        guard limit > 0 else { return [] }
        return stationSuggestions(matching: query, limit: limit)
    }

    private func stationSuggestions(matching query: String, limit: Int?) -> [Station] {
        let q = Self.normalize(query)

        guard !q.isEmpty else { return [] }

        var ranked = Array(repeating: [Station](), count: 4)
        for entry in searchCandidates(for: q) {
            guard entry.normalizedName.contains(q) else { continue }
            let rank: Int
            if entry.normalizedName == q {
                rank = 0
            } else if entry.normalizedName.hasPrefix(q) {
                rank = 1
            } else if entry.words.contains(where: { $0.hasPrefix(q) }) {
                rank = 2
            } else {
                rank = 3
            }
            if limit.map({ ranked[rank].count < $0 }) ?? true {
                ranked[rank].append(entry.station)
            }
        }
        let results = ranked.flatMap { $0 }
        guard let limit else { return results }
        return Array(results.prefix(limit))
    }

    func indexedCandidateCount(matching query: String) -> Int {
        let normalized = Self.normalize(query)
        guard !normalized.isEmpty else { return 0 }
        return searchCandidates(for: normalized).count
    }

    private func searchCandidates(for normalizedQuery: String) -> [SearchEntry] {
        let queryBigrams = Set(Self.bigrams(in: normalizedQuery))
        guard !queryBigrams.isEmpty else { return searchIndex }

        let postingLists = queryBigrams.compactMap { bigram -> (bigram: String, indices: [Int])? in
            guard let indices = searchBigramIndex[bigram] else { return nil }
            return (bigram, indices)
        }
        guard postingLists.count == queryBigrams.count else { return [] }

        let orderedLists = postingLists.sorted {
            ($0.indices.count, $0.bigram) < ($1.indices.count, $1.bigram)
        }
        var candidateIndices = orderedLists[0].indices
        for postingList in orderedLists.dropFirst() {
            candidateIndices = Self.intersection(candidateIndices, postingList.indices)
            if candidateIndices.isEmpty { break }
        }
        return candidateIndices.map { searchIndex[$0] }
    }

    func station(id: Int) -> Station? { stationsByID[id] }

    func station(diva: Int) -> Station? { stationsByDiva[diva] }

    // for nearby stations
    func stations(
        near location: CLLocation,
        radiusInMeters radius: Double
    ) -> [Station] {
        stationsWithDistance(near: location, radiusInMeters: radius).map(\.station)
    }

    // Performs the exact Core Location calculation once so nearby consumers
    // can filter, sort, limit, and render using the same distance value.
    func stationsWithDistance(
        near location: CLLocation,
        radiusInMeters radius: Double
    ) -> [StationDistance] {
        var results: [StationDistance] = []
        forEachStationDistance(near: location, radiusInMeters: radius) { results.append($0) }
        return results
    }

    // Keeps only the closest requested stations while scanning the spatial
    // buckets, avoiding a full in-radius result allocation and sort.
    func nearestStationsWithDistance(
        near location: CLLocation,
        radiusInMeters radius: Double,
        limit: Int
    ) -> [StationDistance] {
        guard limit > 0 else { return [] }
        var heap: [StationDistance] = []
        heap.reserveCapacity(limit)
        forEachStationDistance(near: location, radiusInMeters: radius) { candidate in
            if heap.count < limit {
                heap.append(candidate)
                Self.siftFarthestUp(in: &heap, from: heap.count - 1)
            } else if let farthest = heap.first, Self.isCloser(candidate, than: farthest) {
                heap[0] = candidate
                Self.siftFarthestDown(in: &heap, from: 0)
            }
        }
        return heap.sorted { Self.isCloser($0, than: $1) }
    }

    private func forEachStationDistance(
        near location: CLLocation,
        radiusInMeters radius: Double,
        _ visit: (StationDistance) -> Void
    ) {
        let center = Self.spatialCell(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let cellRadius = max(1, Int(ceil(radius / 700)))
        for latitudeOffset in -cellRadius...cellRadius {
            for longitudeOffset in -cellRadius...cellRadius {
                let cell = SpatialCell(
                    latitude: center.latitude + latitudeOffset,
                    longitude: center.longitude + longitudeOffset
                )
                guard let candidates = spatialIndex[cell] else { continue }
                for station in candidates {
                    let stationLocation = CLLocation(
                        latitude: station.lat,
                        longitude: station.lon
                    )
                    let distance = stationLocation.distance(from: location)
                    guard distance <= radius else { continue }
                    visit(StationDistance(station: station, meters: distance))
                }
            }
        }
    }

    private static func isCloser(_ lhs: StationDistance, than rhs: StationDistance) -> Bool {
        (lhs.meters, lhs.station.id) < (rhs.meters, rhs.station.id)
    }

    private static func siftFarthestUp(in heap: inout [StationDistance], from index: Int) {
        var child = index
        while child > 0 {
            let parent = (child - 1) / 2
            guard isCloser(heap[parent], than: heap[child]) else { return }
            heap.swapAt(parent, child)
            child = parent
        }
    }

    private static func siftFarthestDown(in heap: inout [StationDistance], from index: Int) {
        var parent = index
        while true {
            let left = parent * 2 + 1
            guard left < heap.count else { return }
            let right = left + 1
            let fartherChild = right < heap.count && isCloser(heap[left], than: heap[right])
                ? right
                : left
            guard isCloser(heap[parent], than: heap[fartherChild]) else { return }
            heap.swapAt(parent, fartherChild)
            parent = fartherChild
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

    nonisolated private static func intersection(_ lhs: [Int], _ rhs: [Int]) -> [Int] {
        var leftIndex = 0
        var rightIndex = 0
        var result: [Int] = []
        result.reserveCapacity(min(lhs.count, rhs.count))

        while leftIndex < lhs.count, rightIndex < rhs.count {
            let left = lhs[leftIndex]
            let right = rhs[rightIndex]
            if left == right {
                result.append(left)
                leftIndex += 1
                rightIndex += 1
            } else if left < right {
                leftIndex += 1
            } else {
                rightIndex += 1
            }
        }
        return result
    }

    nonisolated private static func spatialCell(latitude: Double, longitude: Double) -> SpatialCell {
        SpatialCell(
            latitude: Int(floor(latitude / Self.spatialCellSize)),
            longitude: Int(floor(longitude / Self.spatialCellSize))
        )
    }
}
