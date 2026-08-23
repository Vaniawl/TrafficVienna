import SwiftUI

enum DesignColor {
    static let brand = Color(hex: 0x41C7AD)
    static let brandDeep = Color(hex: 0x21B66F)
    static let brandDark = Color(hex: 0x087A5B)
    static let accentText = Color.adaptive(light: 0x087A5B, dark: 0x41C7AD)
    static let heroStart = Color(hex: 0x00664B)
    static let heroEnd = Color(hex: 0x003F30)
    static let brandGradient = LinearGradient(
        colors: [heroStart, heroEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let background = Color.adaptive(light: 0xF5F6F4, dark: 0x0D0F0E)
    static let secondaryBackground = Color.adaptive(light: 0xEFF2F0, dark: 0x121513)
    static let cardBackground = Color.adaptive(light: 0xFFFFFF, dark: 0x191C1A)
    static let elevatedBackground = Color.adaptive(light: 0xFFFFFF, dark: 0x202321)

    static let primaryText = Color.adaptive(light: 0x101114, dark: 0xF5F6F4)
    static let secondaryText = Color.adaptive(light: 0x4F5559, dark: 0xAEB4B0)
    static let tertiaryText = Color.adaptive(light: 0x5E6468, dark: 0x9AA19C)
    static let inverseText = Color.white

    static let border = Color.adaptive(light: 0xE7E9E8, dark: 0x303431)
    static let separator = Color.adaptive(light: 0xECEEED, dark: 0x292D2A)

    static let success = Color.adaptive(light: 0x087A5B, dark: 0x41C7AD)
    static let warning = Color.adaptive(light: 0x8A4D00, dark: 0xFFB55C)
    static let error = Color.adaptive(light: 0xB42318, dark: 0xFF8A80)
    static let info = Color.adaptive(light: 0x245FA3, dark: 0x73A7E8)
}

private extension Color {
    static func adaptive(light: UInt, dark: UInt) -> Color {
        Color(uiColor: UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        })
    }
}
