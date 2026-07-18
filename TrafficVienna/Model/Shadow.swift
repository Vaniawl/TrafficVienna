import SwiftUI

enum Shadow {
    static let none = (color: Color.clear, radius: 0.0, x: 0.0, y: 0.0)
    static let sm = (color: Color.black.opacity(0.04), radius: 4.0, x: 0.0, y: 2.0)
    static let md = (color: Color.black.opacity(0.06), radius: 12.0, x: 0.0, y: 5.0)
    static let lg = (color: Color.black.opacity(0.08), radius: 20.0, x: 0.0, y: 10.0)
}
