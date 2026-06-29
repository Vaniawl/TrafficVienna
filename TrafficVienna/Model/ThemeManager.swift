import SwiftUI
import Combine

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var preset: ThemePreset {
        didSet {
            UserDefaults.standard.set(preset.rawValue, forKey: "themePreset")
        }
    }

    private init() {
        let raw = UserDefaults.standard.string(forKey: "themePreset") ?? ThemePreset.indigo.rawValue
        preset = ThemePreset(rawValue: raw) ?? .indigo
    }
}
