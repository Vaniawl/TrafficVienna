//
//  Favorites.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 29.11.25.
//

import Foundation

struct FavoriteRoute: Codable, Hashable {
    let diva: String
    let lineName: String
    let destination: String
}



enum FavoritesManager {
    // Key for storing favorites
    private static let key = "favorite_routes"
    // Shared storage APP GROUP
    private static let defaults = UserDefaults(suiteName: "group.wellbe.TrafficVienna")!
    
    // MARK: - Load and save
        private static func load() -> Set<FavoriteRoute> {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(Set<FavoriteRoute>.self, from: data)
        else {
            return []
        }
        return decoded
    }
    
    private static func save(_ routes: Set<FavoriteRoute>) {
        let data = try? JSONEncoder().encode(routes)
        defaults.set(data, forKey: key)
    }
    
    // MARK: Public API
    static func isFavorite(diva: String, lineName: String, destination: String) -> Bool {
        let fav = FavoriteRoute(diva: diva, lineName: lineName, destination: destination)
        return load().contains(fav)
    }

    
    static func toggle(diva: String, lineName: String, destination: String) {
        var set = load()
        let fav = FavoriteRoute(diva: diva, lineName: lineName, destination: destination)
        
        if set.contains(fav) {
            set.remove(fav)
        } else {
            set.insert(fav)
        }
        save(set)
    }
    
    static func all() -> [FavoriteRoute] {
        Array(load())
    }
    
    static func clear() {
        save([])
    }
    
    static func removeAll() {
        defaults.removeObject(forKey: key)
    }
}


