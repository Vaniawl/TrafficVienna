//
//  RecentSearchesStore.swift
//  TrafficVienna
//
//  Remembers the stations the user recently opened from search, most recent
//  first, so they can jump back quickly.
//

import Foundation
import Combine

final class RecentSearchesStore: ObservableObject {
    @Published private(set) var ids: [Int] = []

    private let key = "recent_search_ids"
    private let maxCount = 8
    private let defaults = UserDefaults.standard

    init() {
        ids = defaults.array(forKey: key) as? [Int] ?? []
    }

    func record(_ id: Int) {
        var list = ids.filter { $0 != id }
        list.insert(id, at: 0)
        ids = Array(list.prefix(maxCount))
        defaults.set(ids, forKey: key)
    }

    func clear() {
        ids = []
        defaults.removeObject(forKey: key)
    }
}
