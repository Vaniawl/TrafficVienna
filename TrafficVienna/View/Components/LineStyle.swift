//
//  LineStyle.swift
//  TrafficVienna
//
//  Visual styling for Wiener Linien lines: official line colors
//  and a reusable line badge used across all screens.
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

// Maps a Wiener Linien line name to its official brand color.
enum LineStyle {
    static func color(for line: String) -> Color {
        let name = line.uppercased().trimmingCharacters(in: .whitespaces)

        // U-Bahn — each line has its own official color
        switch name {
        case "U1": return Color(hex: 0xE20917) // red
        case "U2": return Color(hex: 0xA862A4) // purple
        case "U3": return Color(hex: 0xEF7C00) // orange
        case "U4": return Color(hex: 0x00963F) // green
        case "U6": return Color(hex: 0x9B6A30) // brown
        default: break
        }

        if name.hasPrefix("U") { return Color(hex: 0x1C6BA0) } // other metro fallback
        if name.hasPrefix("S") { return Color(hex: 0x004A99) } // S-Bahn blue
        if name.hasPrefix("N") { return Color(hex: 0x1A2A6C) } // night bus dark blue

        // City buses: digits followed by A/B (e.g. 13A, 59B)
        if name.range(of: "^[0-9]+[AB]$", options: .regularExpression) != nil {
            return Color(hex: 0x004A99) // bus blue
        }

        // Everything else (numbers, single letters like D/O) is a tram
        return Color(hex: 0xE2002A) // tram red
    }
}

// A colored capsule showing a line name, e.g. "U1" or "62".
struct LineBadge: View {
    let line: String
    var size: Size = .regular

    enum Size { case small, regular }

    var body: some View {
        Text(line)
            .font(size == .small ? .caption.bold() : .subheadline.bold())
            .foregroundStyle(.white)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, size == .small ? 7 : 9)
            .padding(.vertical, size == .small ? 2 : 3)
            .background(LineStyle.color(for: line), in: RoundedRectangle(cornerRadius: 6))
    }
}

#Preview {
    HStack {
        ForEach(["U1", "U2", "U3", "U4", "U6", "62", "D", "59A", "N25"], id: \.self) {
            LineBadge(line: $0)
        }
    }
    .padding()
}
