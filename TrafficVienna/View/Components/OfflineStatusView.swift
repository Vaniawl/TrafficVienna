import SwiftUI

struct OfflineStatusView: View {
    var body: some View {
        Label("Offline", systemImage: "wifi.slash")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(DesignColor.error)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(DesignColor.cardBackground, in: Capsule())
            .overlay {
                Capsule().stroke(DesignColor.error.opacity(0.3), lineWidth: 1)
            }
            .shadow(
                color: Shadow.sm.color,
                radius: Shadow.sm.radius,
                x: Shadow.sm.x,
                y: Shadow.sm.y
            )
            .padding(.top, Spacing.xs)
            .accessibilityLabel("No connection")
    }
}
