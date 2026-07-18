import Foundation
import Combine

@MainActor
final class DisruptionsViewModel: ObservableObject {
    @Published private(set) var infos: [TrafficInfo] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var categoryFilter: LineCategory?
    @Published var lineFilter = ""
    @Published private(set) var freshness: DataFreshness?
    @Published private(set) var relevantCount = 0

    private let service: MonitorService
    private let favoritesRepo: FavoritesRepository
    private var favouriteLines: Set<String>
    private var relevantInfoIDs: Set<String> = []

    init(service: MonitorService = .shared, favoritesRepo: FavoritesRepository = UserDefaultsFavoritesRepository()) {
        self.service = service
        self.favoritesRepo = favoritesRepo
        self.favouriteLines = Set(favoritesRepo.getAll().map(\.lineName))
    }

    var availableCategories: [LineCategory] {
        let present = Set(infos.flatMap { info in
            (info.relatedLines ?? []).map(LineCategory.of)
        })
        return LineCategory.allCases.filter { present.contains($0) }
    }

    var filteredInfos: [TrafficInfo] {
        var result = infos
        if let categoryFilter {
            result = result.filter { info in
                (info.relatedLines ?? []).contains { LineCategory.of($0) == categoryFilter }
            }
        }
        if !lineFilter.isEmpty {
            result = result.filter { info in
                (info.relatedLines ?? []).contains { $0.localizedCaseInsensitiveContains(lineFilter) }
            }
        }
        let relevant = result.filter(isRelevant)
        return relevant + result.filter { !isRelevant($0) }
    }

    func isRelevant(_ info: TrafficInfo) -> Bool {
        relevantInfoIDs.contains(info.id)
    }

    func updateFavoriteRoutes(_ routes: [FavoriteRoute]) {
        favouriteLines = Set(routes.map(\.lineName))
        rebuildRelevance()
    }

    func load(force: Bool = false) async {
        favouriteLines = Set(favoritesRepo.getAll().map(\.lineName))
        if infos.isEmpty { isLoading = true }
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await service.trafficInfoResult(forceRefresh: force)
            infos = result.value
            rebuildRelevance()
            freshness = result.freshness
        } catch {
            if infos.isEmpty { errorMessage = error.monitorDisplayMessage }
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
    }
}
