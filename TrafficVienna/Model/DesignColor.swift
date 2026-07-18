import SwiftUI

enum DesignColor {
    static let brand = Color(hex: 0xE20917)
    static let brandDeep = Color(hex: 0xA90712)
    static let brandGradient = LinearGradient(
        colors: [brand, brandDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let background = Color(.systemGroupedBackground)
    static let secondaryBackground = Color(.systemGroupedBackground)
    static let cardBackground = Color(.secondarySystemGroupedBackground)

    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let tertiaryText = Color(.tertiaryLabel)
    static let inverseText = Color.white

    static let border = Color(.systemGray4)
    static let separator = Color(.systemGray3)

    static let success = Color(.systemGreen)
    static let warning = Color(.systemOrange)
    static let error = Color(.systemRed)
    static let info = Color(.systemBlue)
}
