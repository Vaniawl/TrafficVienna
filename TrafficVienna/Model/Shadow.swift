import SwiftUI

enum Shadow {
    static let none = (color: Color.clear, radius: 0.0, x: 0.0, y: 0.0)
    static let sm = (color: Color.black.opacity(0.035), radius: 5.0, x: 0.0, y: 2.0)
    static let md = (color: Color.black.opacity(0.055), radius: 14.0, x: 0.0, y: 6.0)
    static let lg = (color: DesignColor.brandDark.opacity(0.14), radius: 24.0, x: 0.0, y: 12.0)
}
