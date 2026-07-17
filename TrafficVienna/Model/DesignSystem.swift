import SwiftUI

// MARK: - Design Tokens

/// Unified color palette for TrafficVienna
enum DesignColor {
    // Primary brand color (Vienna transport red)
    static let brand: Color = Color(hex: 0xE20917)
    
    // Background colors
    static let background: Color = Color(.systemBackground)
    static let secondaryBackground: Color = Color(.systemGroupedBackground)
    static let cardBackground: Color = Color(.systemBackground)
    
    // Text colors
    static let primaryText: Color = Color(.label)
    static let secondaryText: Color = Color(.secondaryLabel)
    static let tertiaryText: Color = Color(.tertiaryLabel)
    static let inverseText: Color = Color(.white)
    
    // Border colors
    static let border: Color = Color(.systemGray4)
    static let separator: Color = Color(.systemGray3)
    
    // Status colors
    static let success: Color = Color(.systemGreen)
    static let warning: Color = Color(.systemOrange)
    static let error: Color = Color(.systemRed)
    static let info: Color = Color(.systemBlue)
    
}


// MARK: - Typography

struct Typography {
    static let headline1 = Font.system(size: 32, weight: .bold, design: .default)
    static let headline2 = Font.system(size: 28, weight: .semibold, design: .default)
    static let headline3 = Font.system(size: 24, weight: .semibold, design: .default)
    static let headline4 = Font.system(size: 20, weight: .semibold, design: .default)
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 15, weight: .regular, design: .default)
    static let caption1 = Font.system(size: 13, weight: .regular, design: .default)
    static let caption2 = Font.system(size: 12, weight: .regular, design: .default)
    static let caption3 = Font.system(size: 11, weight: .regular, design: .default)
    
    static let bold = Font.system(weight: .bold)
    static let semibold = Font.system(weight: .semibold)
    static let medium = Font.system(weight: .medium)
    static let regular = Font.system(weight: .regular)
}

// MARK: - Spacing

struct Spacing {
    static let none: CGFloat = 0
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

// MARK: - Corner Radius

struct CornerRadius {
    static let none: CGFloat = 0
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let full: CGFloat = 9999
}

// MARK: - Shadow (parameters for .shadow() modifier)
/// Shadow(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)

struct Shadow {
    static let none = (color: Color.clear, radius: 0.0, x: 0.0, y: 0.0)
    static let sm = (color: Color.black.opacity(0.05), radius: 4.0, x: 0.0, y: 2.0)
    static let md = (color: Color.black.opacity(0.1), radius: 8.0, x: 0.0, y: 4.0)
    static let lg = (color: Color.black.opacity(0.12), radius: 16.0, x: 0.0, y: 8.0)
}

