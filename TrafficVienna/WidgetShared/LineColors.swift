//
//  LineColors.swift
//  TrafficVienna
//
//  Single source of truth for Wiener Linien line styling, shared between the
//  app and the widget extension so both render identical brand colours and
//  classify lines the same way. (Previously the colour map was duplicated in
//  the widget target, which let the two drift apart.)
//

import SwiftUI

// Builds a SwiftUI Color from a 0xRRGGBB hex value.
extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

// The kind of service a line belongs to. Used for colouring and for the
// line-type filter on the station detail screen.
enum LineCategory: String, CaseIterable, Identifiable {
    case metro = "U-Bahn"
    case sbahn = "S-Bahn"
    case tram = "Tram"
    case bus = "Bus"
    case night = "Night"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .metro: return "subway.fill"
        case .sbahn: return "tram"
        case .tram:  return "tram.fill"
        case .bus:   return "bus.fill"
        case .night: return "moon.stars.fill"
        }
    }

    var color: Color {
        switch self {
        case .metro: return Color(hex: 0x1C6BA0)
        case .sbahn: return Color(hex: 0x004A99)
        case .tram:  return Color(hex: 0xE2002A)
        case .bus:   return Color(hex: 0x004A99)
        case .night: return Color(hex: 0x1A2A6C)
        }
    }

    // Classifies a Wiener Linien line name into a service category.
    static func of(_ line: String) -> LineCategory {
        let name = line.uppercased().trimmingCharacters(in: .whitespaces)
        if name.hasPrefix("N") { return .night }
        if name.hasPrefix("U") { return .metro }
        if name.hasPrefix("S") { return .sbahn }
        // City buses: digits followed by A/B (e.g. 13A, 59B).
        if name.range(of: "^[0-9]+[AB]$", options: .regularExpression) != nil { return .bus }
        return .tram
    }
}

// Maps a Wiener Linien line name to its official brand colour.
enum LineColors {
    static func color(for line: String) -> Color {
        let name = line.uppercased().trimmingCharacters(in: .whitespaces)

        // U-Bahn — each line has its own official colour.
        switch name {
        case "U1": return Color(hex: 0xE20917) // red
        case "U2": return Color(hex: 0xA862A4) // purple
        case "U3": return Color(hex: 0xEF7C00) // orange
        case "U4": return Color(hex: 0x00963F) // green
        case "U6": return Color(hex: 0x9B6A30) // brown
        default: break
        }

        switch LineCategory.of(name) {
        case .metro: return Color(hex: 0x1C6BA0) // other metro fallback
        case .sbahn: return Color(hex: 0x004A99) // S-Bahn blue
        case .night: return Color(hex: 0x1A2A6C) // night bus dark blue
        case .bus:   return Color(hex: 0x004A99) // bus blue
        case .tram:  return Color(hex: 0xE2002A) // tram red
        }
    }
}
