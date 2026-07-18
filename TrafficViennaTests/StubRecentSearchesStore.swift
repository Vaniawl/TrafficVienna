@testable import TrafficVienna

final class StubRecentSearchesStore: RecentSearchesStoring {
    private(set) var ids: [Int]

    init(ids: [Int] = []) {
        self.ids = ids
    }

    func record(_ id: Int) {
        ids.removeAll { $0 == id }
        ids.insert(id, at: 0)
    }

    func clear() {
        ids = []
    }
}
