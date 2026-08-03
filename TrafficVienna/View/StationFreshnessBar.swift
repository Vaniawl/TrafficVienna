import SwiftUI

struct StationFreshnessBar: View {
    let lastUpdated: Date
    let isStale: Bool

    var body: some View {
        Label {
            if isStale {
                Text("Saved at \(lastUpdated, format: .dateTime.hour().minute())")
            } else {
                Text("Updated at \(lastUpdated, format: .dateTime.hour().minute())")
            }
        } icon: {
            Image(systemName: isStale ? "clock.badge.exclamationmark" : "dot.radiowaves.left.and.right")
                .foregroundStyle(isStale ? .orange : .green)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
    }
}
