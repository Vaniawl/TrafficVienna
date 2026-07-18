import Foundation
import Combine

@MainActor
final class DisruptionsViewModel: ObservableObject {
    @Published private(set) var infos: [TrafficInfo] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var categoryFilter: LineCategory?
    @Published var lineFilter = ""

    private let service: MonitorService
    private let favoritesRepo: FavoritesRepository

    init(service: MonitorService = .shared, favoritesRepo: FavoritesRepository = UserDefaultsFavoritesRepository()) {
        self.service = service
        self.favoritesRepo = favoritesRepo
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
        return result.sorted { isRelevant($0) && !isRelevant($1) }
    }

    var relevantCount: Int { infos.filter(isRelevant).count }

    func isRelevant(_ info: TrafficInfo) -> Bool {
        let favouriteLines = Set(favoritesRepo.getAll().map(\.lineName))
        return !(Set(info.relatedLines ?? []).intersection(favouriteLines).isEmpty)
    }

    func load(force: Bool = false) async {
        if infos.isEmpty { isLoading = true }
        errorMessage = nil
        defer { isLoading = false }

        do {
            infos = try await service.trafficInfoList(forceRefresh: force)
        } catch {
            if infos.isEmpty { errorMessage = error.monitorDisplayMessage }
        }
    }
}
