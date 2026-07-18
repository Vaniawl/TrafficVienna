import Foundation
import OSLog

private let log = Logger(subsystem: "at.wellbe.TrafficVienna", category: "store")

final class RecentSearchesStore: RecentSearchesStoring {
    private(set) var ids: [Int] = []

    private let key: String
    private let maxCount: Int
    private let defaults: UserDefaults

    init(
        defaults: UserDefaults? = UserDefaults(suiteName: "group.wellbe.TrafficVienna"),
        key: String = "recent_search_ids",
        maxCount: Int = 8
    ) {
        let groupID = "group.wellbe.TrafficVienna"
        if let defaults {
            self.defaults = defaults
        } else {
            log.error("RecentSearchesStore: App Group \(groupID) unavailable, falling back to standard")
            self.defaults = .standard
        }
        self.key = key
        self.maxCount = maxCount
        ids = self.defaults.array(forKey: key) as? [Int] ?? []
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
