import Combine
import Foundation

enum HomeModule: String, CaseIterable, Identifiable {
    case savedStations
    case savedRoutes
    case smartInsight

    var id: String { rawValue }
}

@MainActor
final class HomePreferences: ObservableObject {
    private enum Key {
        static let savedStations = "home.showSavedStations"
        static let savedRoutes = "home.showSavedRoutes"
        static let smartInsight = "home.showSmartInsight"
        static let moduleOrder = "home.moduleOrder"
    }

    private let defaults: UserDefaults

    @Published var showsSavedStations: Bool {
        didSet { defaults.set(showsSavedStations, forKey: Key.savedStations) }
    }

    @Published var showsSavedRoutes: Bool {
        didSet { defaults.set(showsSavedRoutes, forKey: Key.savedRoutes) }
    }

    @Published var showsSmartInsight: Bool {
        didSet { defaults.set(showsSmartInsight, forKey: Key.smartInsight) }
    }

    @Published private(set) var moduleOrder: [HomeModule] {
        didSet { defaults.set(moduleOrder.map(\.rawValue), forKey: Key.moduleOrder) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        showsSavedStations = defaults.object(forKey: Key.savedStations) as? Bool ?? true
        showsSavedRoutes = defaults.object(forKey: Key.savedRoutes) as? Bool ?? true
        showsSmartInsight = defaults.object(forKey: Key.smartInsight) as? Bool ?? true
        moduleOrder = Self.normalizedOrder(defaults.stringArray(forKey: Key.moduleOrder) ?? [])
    }

    var isDefault: Bool {
        showsSavedStations
            && showsSavedRoutes
            && showsSmartInsight
            && moduleOrder == HomeModule.allCases
    }

    func restoreDefaults() {
        showsSavedStations = true
        showsSavedRoutes = true
        showsSmartInsight = true
        moduleOrder = HomeModule.allCases
    }

    func isVisible(_ module: HomeModule) -> Bool {
        switch module {
        case .savedStations: showsSavedStations
        case .savedRoutes: showsSavedRoutes
        case .smartInsight: showsSmartInsight
        }
    }

    func setVisible(_ isVisible: Bool, for module: HomeModule) {
        switch module {
        case .savedStations: showsSavedStations = isVisible
        case .savedRoutes: showsSavedRoutes = isVisible
        case .smartInsight: showsSmartInsight = isVisible
        }
    }

    func moveModules(fromOffsets: IndexSet, toOffset: Int) {
        let moving = fromOffsets.sorted().map { moduleOrder[$0] }
        var remaining = moduleOrder.enumerated()
            .filter { !fromOffsets.contains($0.offset) }
            .map(\.element)
        let removedBeforeDestination = fromOffsets.filter { $0 < toOffset }.count
        let destination = min(max(0, toOffset - removedBeforeDestination), remaining.count)
        remaining.insert(contentsOf: moving, at: destination)
        moduleOrder = remaining
    }

    private nonisolated static func normalizedOrder(_ rawValues: [String]) -> [HomeModule] {
        var seen = Set<HomeModule>()
        let stored = rawValues.compactMap(HomeModule.init(rawValue:)).filter { seen.insert($0).inserted }
        return stored + HomeModule.allCases.filter { !seen.contains($0) }
    }
}
