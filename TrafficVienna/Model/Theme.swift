import SwiftUI

enum BackgroundStyle {
    case system
    case grouped

    var color: Color {
        switch self {
        case .system: return Color(.systemBackground)
        case .grouped: return Color(.systemGroupedBackground)
        }
    }
}

enum CardStyle {
    case flat
    case elevated
}

enum ThemePreset: String, CaseIterable, Identifiable {
    case indigo
    case vienna
    case dashboard
    case twilight
    case forest
    case ocean
    case rose
    case monochrome
    case amber
    case night

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .indigo: return "Indigo"
        case .vienna: return "Vienna"
        case .dashboard: return "Dashboard"
        case .twilight: return "Twilight"
        case .forest: return "Forest"
        case .ocean: return "Ocean"
        case .rose: return "Rose"
        case .monochrome: return "Monochrome"
        case .amber: return "Amber"
        case .night: return "Night"
        }
    }

    var accentColor: Color {
        // Legacy values remain decodable for backups, but the product now has
        // one visual identity instead of user-selectable themes.
        Color(hex: 0x22B98B)
    }

    var colorScheme: ColorScheme? {
        nil
    }

    var backgroundStyle: BackgroundStyle {
        .grouped
    }

    var cardStyle: CardStyle {
        .flat
    }
}
