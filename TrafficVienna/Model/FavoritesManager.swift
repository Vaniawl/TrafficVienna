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
    func setOrder(_ routes: [FavoriteRoute])
    func removeAll()
}



nonisolated final class UserDefaultsFavoritesRepository: FavoritesRepository {
    // Key for storing favorites
    private let key = "favorite_routes"
    // Shared storage APP GROUP. UserDefaults is thread-safe but not marked
    // Sendable, so we opt out of the check explicitly.
    private nonisolated(unsafe) let storage: UserDefaults
    
    init(storage: UserDefaults = UserDefaults(suiteName: "group.wellbe.TrafficVienna") ?? .standard) {
        self.storage = storage
    }
    
    
    func isFavorite(diva: String, lineName: String, destination: String) -> Bool {
        let fav = FavoriteRoute(diva: diva, lineName: lineName, destination: destination)
        return load().contains(fav)
    }
    
    func toggle(diva: String, lineName: String, destination: String) {
        var routes = load()
        let fav = FavoriteRoute(diva: diva, lineName: lineName, destination: destination)
        
        if let index = routes.firstIndex(of: fav) {
            routes.remove(at: index)
        } else {
            routes.append(fav)
        }
        save(routes)
    }
    
    func getAll() -> [FavoriteRoute] {
        load()
    }

    func setOrder(_ routes: [FavoriteRoute]) {
        var seen = Set<FavoriteRoute>()
        save(routes.filter { seen.insert($0).inserted })
    }
    
    func removeAll() {
        storage.removeObject(forKey: key)
    }
    
    
    // Private helpers
    private func load() -> [FavoriteRoute] {
        guard let data = storage.data(forKey: key),
              let decoded = try? JSONDecoder().decode([FavoriteRoute].self, from: data)
        else {
            return []
        }
        var seen = Set<FavoriteRoute>()
        return decoded.filter { seen.insert($0).inserted }
    }
    
    private func save(_ routes: [FavoriteRoute]) {
        let data = try? JSONEncoder().encode(routes)
        storage.set(data, forKey: key)
    }
    
    // to check if isFavorite
    
    func clear() {
        save([])
    }
}
