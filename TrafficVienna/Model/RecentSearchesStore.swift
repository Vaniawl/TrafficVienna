import Foundation
import Combine
import OSLog

private let log = Logger(subsystem: "at.wellbe.TrafficVienna", category: "store")

final class RecentSearchesStore: ObservableObject {
    @Published private(set) var ids: [Int] = []

    private let key = "recent_search_ids"
    private let maxCount = 8
    private let defaults: UserDefaults

    init(defaults providedDefaults: UserDefaults? = UserDefaults(suiteName: "group.wellbe.TrafficVienna")) {
        let groupID = "group.wellbe.TrafficVienna"
        guard let store = providedDefaults else {
            log.error("RecentSearchesStore: App Group \(groupID) unavailable, falling back to standard")
            defaults = .standard
            ids = []
            return
        }
        defaults = store
        ids = store.array(forKey: key) as? [Int] ?? []
    }

    func record(_ id: Int) {
        var list = ids.filter { $0 != id }
        list.insert(id, at: 0)
        ids = Array(list.prefix(maxCount))
        defaults.set(ids, forKey: key)
    }

    func remove(_ id: Int) {
        let updated = ids.filter { $0 != id }
        guard updated != ids else { return }
        ids = updated
        if ids.isEmpty {
            defaults.removeObject(forKey: key)
        } else {
            defaults.set(ids, forKey: key)
        }
    }

    func clear() {
        ids = []
        defaults.removeObject(forKey: key)
    }
}
