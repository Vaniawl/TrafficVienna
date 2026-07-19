import Foundation
import Combine

@MainActor
final class DisruptionsViewModel: ObservableObject {
    @Published private(set) var infos: [TrafficInfo] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isRefreshing = false
    @Published var errorMessage: String?
    @Published var categoryFilter: LineCategory? {
        didSet { rebuildFilteredInfos() }
    }
    @Published var lineFilter = "" {
        didSet { rebuildFilteredInfos() }
    }
    @Published private(set) var freshness: DataFreshness?
    @Published private(set) var relevantCount = 0
    @Published private(set) var availableCategories: [LineCategory] = []
    @Published private(set) var filteredInfos: [TrafficInfo] = []

    private let service: MonitorService
    private let favoritesRepo: FavoritesRepository
    private var favouriteLines: Set<String>
    private var relevantInfoIDs: Set<String> = []
    private var isRequesting = false
    private var loadGeneration = 0

    init(service: MonitorService = .shared, favoritesRepo: FavoritesRepository = UserDefaultsFavoritesRepository()) {
        self.service = service
        self.favoritesRepo = favoritesRepo
        self.favouriteLines = Set(favoritesRepo.getAll().map(\.lineName))
    }

    func isRelevant(_ info: TrafficInfo) -> Bool {
        relevantInfoIDs.contains(info.id)
    }

    func updateFavoriteRoutes(_ routes: [FavoriteRoute]) {
        favouriteLines = Set(routes.map(\.lineName))
        rebuildRelevance()
    }

    func load(force: Bool = false) async {
        guard force || !isRequesting else { return }
        loadGeneration &+= 1
        let generation = loadGeneration
        isRequesting = true
        favouriteLines = Set(favoritesRepo.getAll().map(\.lineName))
        if infos.isEmpty { isLoading = true } else { isRefreshing = true }
        errorMessage = nil
        defer {
            if generation == loadGeneration {
                isRequesting = false
                isLoading = false
                isRefreshing = false
            }
        }

        do {
            let result = try await service.trafficInfoResult(forceRefresh: force)
            guard !Task.isCancelled, generation == loadGeneration else { return }
            infos = result.value
            rebuildAvailableCategories()
            rebuildRelevance()
            freshness = result.freshness
        } catch {
            guard !Task.isCancelled, generation == loadGeneration else { return }
            errorMessage = error.monitorDisplayMessage
        }
    }

    var staleMessage: String? {
        guard case let .stale(_, message) = freshness else { return nil }
        return message
    }

    private func rebuildRelevance() {
        relevantInfoIDs = Set(infos.lazy.filter { info in
            (info.relatedLines ?? []).contains(where: self.favouriteLines.contains)
        }.map(\.id))
        relevantCount = relevantInfoIDs.count
        rebuildFilteredInfos()
    }

    private func rebuildAvailableCategories() {
        let present = Set(infos.flatMap { info in
            (info.relatedLines ?? []).map(LineCategory.of)
        })
        availableCategories = LineCategory.allCases.filter(present.contains)
    }

    private func rebuildFilteredInfos() {
        var relevant: [TrafficInfo] = []
        var other: [TrafficInfo] = []
        relevant.reserveCapacity(relevantCount)
        other.reserveCapacity(max(0, infos.count - relevantCount))

        for info in infos {
            let lines = info.relatedLines ?? []
            if let categoryFilter,
               !lines.contains(where: { LineCategory.of($0) == categoryFilter }) {
                continue
            }
            if !lineFilter.isEmpty,
               !lines.contains(where: { $0.localizedCaseInsensitiveContains(lineFilter) }) {
                continue
            }

            if relevantInfoIDs.contains(info.id) {
                relevant.append(info)
            } else {
                other.append(info)
            }
        }

        relevant.append(contentsOf: other)
        filteredInfos = relevant
    }
}
