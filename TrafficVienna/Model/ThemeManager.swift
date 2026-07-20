import SwiftUI
import Combine

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    private let defaults: UserDefaults

    @Published var preset: ThemePreset {
        didSet {
            defaults.set(preset.rawValue, forKey: "themePreset")
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let raw = defaults.string(forKey: "themePreset") ?? ThemePreset.dashboard.rawValue
        preset = ThemePreset(rawValue: raw) ?? .dashboard
    }
}
