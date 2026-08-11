import SwiftUI

struct PremiumSurface: ViewModifier {
    var cornerRadius: CGFloat = CornerRadius.lg
    var elevated = false

    func body(content: Content) -> some View {
        content
            .background(
                elevated ? DesignColor.elevatedBackground : DesignColor.cardBackground,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(DesignColor.border, lineWidth: 1)
            }
            .shadow(
                color: elevated ? Shadow.md.color : Shadow.sm.color,
                radius: elevated ? Shadow.md.radius : Shadow.sm.radius,
                x: elevated ? Shadow.md.x : Shadow.sm.x,
                y: elevated ? Shadow.md.y : Shadow.sm.y
            )
    }
}

extension View {
    func premiumSurface(
        cornerRadius: CGFloat = CornerRadius.lg,
        elevated: Bool = false
    ) -> some View {
        modifier(PremiumSurface(cornerRadius: cornerRadius, elevated: elevated))
    }
}
