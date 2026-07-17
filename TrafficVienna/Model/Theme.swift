import SwiftUI

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
        switch self {
        case .indigo: return .indigo
        case .vienna: return Color(hex: 0xE20917)
        case .dashboard: return Color(hex: 0x007AFF)
        case .twilight: return Color(hex: 0x6B4EFF)
        case .forest: return Color(hex: 0x34A853)
        case .ocean: return Color(hex: 0x00BFA5)
        case .rose: return Color(hex: 0xFF4D8C)
        case .monochrome: return Color(hex: 0x8E8E93)
        case .amber: return Color(hex: 0xFF9500)
        case .night: return Color(hex: 0x5E5CE6)
        }
    }

}
