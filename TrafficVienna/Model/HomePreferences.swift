import Combine
import Foundation

@MainActor
final class HomePreferences: ObservableObject {
    private enum Key {
        static let savedStations = "home.showSavedStations"
        static let savedRoutes = "home.showSavedRoutes"
        static let smartInsight = "home.showSmartInsight"
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

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        showsSavedStations = defaults.object(forKey: Key.savedStations) as? Bool ?? true
        showsSavedRoutes = defaults.object(forKey: Key.savedRoutes) as? Bool ?? true
        showsSmartInsight = defaults.object(forKey: Key.smartInsight) as? Bool ?? true
    }

    var isDefault: Bool {
        showsSavedStations && showsSavedRoutes && showsSmartInsight
    }

    func restoreDefaults() {
        showsSavedStations = true
        showsSavedRoutes = true
        showsSmartInsight = true
    }
}
