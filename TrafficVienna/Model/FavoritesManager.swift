//
//  Favorites.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 29.11.25.
//

import Foundation

// describes one users favotite route
nonisolated struct FavoriteRoute: Codable, Hashable {
    let diva: String
    let lineName: String
    let destination: String
}

protocol FavoritesRepository: Sendable {
    func isFavorite(diva: String, lineName: String, destination: String) -> Bool
    func toggle(diva: String, lineName: String, destination: String)
    func getAll() -> [FavoriteRoute]
    func removeAll()
}



nonisolated final class UserDefaultsFavoritesRepository: FavoritesRepository {
    // Key for storing favorites
    private let key = "favorite_routes"
    // Shared storage APP GROUP. UserDefaults is thread-safe but not marked
    // Sendable, so we opt out of the check explicitly.
    private nonisolated(unsafe) let storage: UserDefaults
    
    init(storage: UserDefaults = UserDefaults(suiteName: "group.wellbe.TrafficVienna")!) {
        self.storage = storage
    }
    
    
    func isFavorite(diva: String, lineName: String, destination: String) -> Bool {
        let fav = FavoriteRoute(diva: diva, lineName: lineName, destination: destination)
        return load().contains(fav)
    }
    
    func toggle(diva: String, lineName: String, destination: String) {
        var set = load()
        let fav = FavoriteRoute(diva: diva, lineName: lineName, destination: destination)
        
        if set.contains(fav) {
            set.remove(fav)
        } else {
            set.insert(fav)
        }
        save(set)
    }
    
    func getAll() -> [FavoriteRoute] {
        Array(load())
    }
    
    func removeAll() {
        storage.removeObject(forKey: key)
    }
    
    
    // Private helpers
    private func load() -> Set<FavoriteRoute> {
        guard let data = storage.data(forKey: key),
              let decoded = try? JSONDecoder().decode(Set<FavoriteRoute>.self, from: data)
        else {
            return []
        }
        return decoded
    }
    
    private func save(_ routes: Set<FavoriteRoute>) {
        let data = try? JSONEncoder().encode(routes)
        storage.set(data, forKey: key)
    }
    
    // to check if isFavorite
    
    func clear() {
        save([])
    }
}


