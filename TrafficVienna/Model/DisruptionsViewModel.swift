import Foundation
import Observation

@MainActor
@Observable
final class DisruptionsViewModel {
    private(set) var infos: [TrafficInfo] = []
    private(set) var state: DisruptionsViewState = .loading
    private(set) var isLoadingRequest = false
    private(set) var isShowingSavedData = false
    private(set) var refreshErrorMessage: String?
    var selectedKind: DisruptionKind = .service
    var categoryFilter: LineCategory?
    var lineFilter = ""

    private let service: TrafficInfoProviding

    init(service: TrafficInfoProviding = MonitorService.shared) {
        self.service = service
    }

    var activeServiceCount: Int {
        infos.count { DisruptionKind(categoryID: $0.categoryID) == .service }
    }

    var dashboardStatus: ServiceDashboardStatus {
        switch state {
        case .loading:
            .loading
        case .failed:
            .unavailable
        case .loaded where activeServiceCount == 0:
            .allClear(isSaved: isShowingSavedData)
        case .loaded:
            .alerts(count: activeServiceCount, isSaved: isShowingSavedData)
        }
    }

    var availableCategories: [LineCategory] {
        let present = Set(kindInfos.flatMap { info in
            (info.relatedLines ?? []).map(LineCategory.of)
        })
        return LineCategory.allCases.filter { present.contains($0) }
    }

    var filteredInfos: [TrafficInfo] {
        var result = kindInfos

        if let categoryFilter {
            result = result.filter { info in
                (info.relatedLines ?? []).contains { LineCategory.of($0) == categoryFilter }
            }
        }

        let query = lineFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter { info in
                info.title.localizedStandardContains(query)
                    || (info.description?.localizedStandardContains(query) ?? false)
                    || (info.relatedLines ?? []).contains { $0.localizedStandardContains(query) }
            }
        }

        return result
    }

    var hasActiveFilters: Bool {
        categoryFilter != nil || !lineFilter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasAlertsForSelectedKind: Bool {
        !kindInfos.isEmpty
    }

    func selectKind(_ kind: DisruptionKind) {
        selectedKind = kind
        categoryFilter = nil
    }

    func clearFilters() {
        categoryFilter = nil
        lineFilter = ""
    }

    func load(force: Bool = false) async {
        guard !isLoadingRequest else { return }
        isLoadingRequest = true
        if infos.isEmpty {
            state = .loading
            isShowingSavedData = false
        }
        refreshErrorMessage = nil
        defer {
            isLoadingRequest = false
        }

        do {
            let snapshot = try await service.trafficInfoSnapshot(forceRefresh: force)
            guard !Task.isCancelled else { return }
            infos = Self.normalized(snapshot.infos)
            isShowingSavedData = snapshot.isStale
            if snapshot.isStale {
                refreshErrorMessage = String(localized: "Showing saved data from the last successful update.")
            }
            state = .loaded
        } catch {
            let message = error.monitorDisplayMessage
            if infos.isEmpty {
                state = .failed(message)
                isShowingSavedData = false
            } else {
                refreshErrorMessage = message
                isShowingSavedData = true
            }
        }
    }

    private var kindInfos: [TrafficInfo] {
        infos.filter { DisruptionKind(categoryID: $0.categoryID) == selectedKind }
    }

    private static func normalized(_ infos: [TrafficInfo]) -> [TrafficInfo] {
        var seen = Set<DisruptionSignature>()
        return infos
            .filter { info in
                seen.insert(DisruptionSignature(info: info)).inserted
            }
            .sorted { lhs, rhs in
                let leftKind = DisruptionKind(categoryID: lhs.categoryID)
                let rightKind = DisruptionKind(categoryID: rhs.categoryID)
                if leftKind != rightKind {
                    return Self.sortIndex(for: leftKind) < Self.sortIndex(for: rightKind)
                }
                return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
            }
    }

    private static func sortIndex(for kind: DisruptionKind) -> Int {
        switch kind {
        case .service: 0
        case .accessibility: 1
        case .stopChange: 2
        }
    }
}
