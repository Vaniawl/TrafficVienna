import SwiftUI

enum Motion {
    static let quick = Animation.snappy(duration: 0.28, extraBounce: 0)
    static let standard = Animation.smooth(duration: 0.38, extraBounce: 0)
    static let livePulse = Animation.easeInOut(duration: 0.9)
    static let shimmer = Animation.linear(duration: 1.25)

    static func quick(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : quick
    }

    static func standard(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : standard
    }

    static func stateTransition(reduceMotion: Bool) -> AnyTransition {
        if reduceMotion {
            .opacity
        } else {
            .opacity.combined(with: .scale(scale: 0.985))
        }
    }

    static func edgeTransition(
        _ edge: Edge,
        reduceMotion: Bool
    ) -> AnyTransition {
        if reduceMotion {
            .opacity
        } else {
            .move(edge: edge).combined(with: .opacity)
        }
    }
}
