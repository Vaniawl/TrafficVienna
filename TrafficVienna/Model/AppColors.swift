import SwiftUI

extension ShapeStyle where Self == Color {
    static var appAccent: Color { DesignColor.brand }
    static var appFaint: Color { Color(.tertiaryLabel) }
    static var appOfflineBg: Color { Color.red.opacity(0.12) }
    static var appErrorBg: Color { Color.yellow.opacity(0.12) }
    static var appChipBg: Color { Color(.quaternarySystemFill) }
}
