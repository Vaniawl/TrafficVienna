import SwiftUI

extension ShapeStyle where Self == Color {
    static var appAccent: Color { DesignColor.brandDark }
    static var appFaint: Color { DesignColor.tertiaryText }
    static var appOfflineBg: Color { DesignColor.error.opacity(0.12) }
    static var appErrorBg: Color { DesignColor.warning.opacity(0.12) }
    static var appChipBg: Color { DesignColor.brand.opacity(0.11) }
}
