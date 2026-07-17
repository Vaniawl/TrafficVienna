import SwiftUI

@MainActor
final class ThemeEngine: ObservableObject {
    enum ThemeMode: String, Codable, CaseIterable, Identifiable {
        case system = "system"
        case light = "light"
        case dark = "dark"

        var id: String { rawValue }

        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }

        var displayName: LocalizedStringKey {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
    }

    @Published var mode: ThemeMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: "themeMode")
        }
    }

    @Published var preset: ThemePreset {
        didSet {
            UserDefaults.standard.set(preset.rawValue, forKey: "themePreset")
        }
    }

    var colorScheme: ColorScheme? {
        return mode.colorScheme
    }

    init() {
        let rawMode = UserDefaults.standard.string(forKey: "themeMode") ?? ThemeMode.system.rawValue
        mode = ThemeMode(rawValue: rawMode) ?? .system

        let rawPreset = UserDefaults.standard.string(forKey: "themePreset") ?? ThemePreset.vienna.rawValue
        preset = ThemePreset(rawValue: rawPreset) ?? .vienna
    }
}
