import SwiftUI

struct PremiumPrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(DesignColor.background)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, Spacing.md)
            .background(
                DesignColor.primaryText.opacity(configuration.isPressed ? 0.82 : 1),
                in: Capsule()
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .animation(Motion.quick(reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}
