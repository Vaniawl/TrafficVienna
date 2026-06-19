//
//  FavoriteStationsRepository.swift
//  TrafficVienna
//
//  Persists whole-station favourites (separate from line favourites) as an
//  ordered list, so the user can pin stations and reorder them by hand.
//

import Foundation

nonisolated struct FavoriteStation: Codable, Hashable, Identifiable {
    let id: Int        // HALTESTELLEN_ID
    let diva: Int?
    let name: String

    init(id: Int, diva: Int?, name: String) {
        self.id = id
        self.diva = diva
        self.name = name
    }

    init(_ station: Station) {
        self.id = station.id
        self.diva = station.diva
        self.name = station.name
    }
}

protocol FavoriteStationsStoring: Sendable {
    func all() -> [FavoriteStation]
    func contains(id: Int) -> Bool
    func toggle(_ station: FavoriteStation)
    func remove(id: Int)
    func setOrder(_ stations: [FavoriteStation])
}

nonisolated final class UserDefaultsFavoriteStationsRepository: FavoriteStationsStoring {
    private let key = "favorite_stations"
    // UserDefaults is thread-safe but not Sendable; opt out explicitly.
    private nonisolated(unsafe) let storage: UserDefaults

    init(storage: UserDefaults = UserDefaults(suiteName: "group.wellbe.TrafficVienna")!) {
        self.storage = storage
    }

    func all() -> [FavoriteStation] { load() }

    func contains(id: Int) -> Bool {
        load().contains { $0.id == id }
    }

    func toggle(_ station: FavoriteStation) {
        var list = load()
        if let index = list.firstIndex(where: { $0.id == station.id }) {
            list.remove(at: index)
        } else {
            list.append(station)
        }
        save(list)
    }

    func remove(id: Int) {
        save(load().filter { $0.id != id })
    }

    func setOrder(_ stations: [FavoriteStation]) {
        save(stations)
    }

    // MARK: - Persistence (ordered array)

    private func load() -> [FavoriteStation] {
        guard let data = storage.data(forKey: key),
              let decoded = try? JSONDecoder().decode([FavoriteStation].self, from: data)
        else { return [] }
        return decoded
    }

    private func save(_ stations: [FavoriteStation]) {
        let data = try? JSONEncoder().encode(stations)
        storage.set(data, forKey: key)
    }
}
