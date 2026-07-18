import SwiftUI

struct OfflineStatusView: View {
    var body: some View {
        Label("Offline", systemImage: "wifi.slash")
            .font(.caption)
            .bold()
            .foregroundStyle(.red)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(.red.opacity(0.12), in: Capsule())
            .padding(.top, Spacing.xs)
            .accessibilityLabel("No connection")
    }
}
