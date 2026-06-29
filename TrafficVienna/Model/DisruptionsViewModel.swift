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

    init(service: MonitorService = .shared) {
        self.service = service
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
        return result
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
