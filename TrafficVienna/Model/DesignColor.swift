import SwiftUI

enum DesignColor {
    static let brand = Color(hex: 0x41C7AD)
    static let brandDeep = Color(hex: 0x21B66F)
    static let brandDark = Color(hex: 0x087A5B)
    static let brandGradient = LinearGradient(
        colors: [brand, brandDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let background = Color.adaptive(light: 0xF5F6F4, dark: 0x0D0F0E)
    static let secondaryBackground = Color.adaptive(light: 0xEFF2F0, dark: 0x121513)
    static let cardBackground = Color.adaptive(light: 0xFFFFFF, dark: 0x191C1A)
    static let elevatedBackground = Color.adaptive(light: 0xFFFFFF, dark: 0x202321)

    static let primaryText = Color.adaptive(light: 0x101114, dark: 0xF5F6F4)
    static let secondaryText = Color.adaptive(light: 0x656B70, dark: 0xAEB4B0)
    static let tertiaryText = Color.adaptive(light: 0x969B9F, dark: 0x7D8580)
    static let inverseText = Color.white

    static let border = Color.adaptive(light: 0xE7E9E8, dark: 0x303431)
    static let separator = Color.adaptive(light: 0xECEEED, dark: 0x292D2A)

    static let success = Color(hex: 0x21B66F)
    static let warning = Color(hex: 0xE59B2F)
    static let error = Color(hex: 0xD84A4A)
    static let info = Color(hex: 0x3478C7)
}

private extension Color {
    static func adaptive(light: UInt, dark: UInt) -> Color {
        Color(uiColor: UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        })
    }
}
