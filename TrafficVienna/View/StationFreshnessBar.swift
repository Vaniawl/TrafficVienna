import SwiftUI

struct StationFreshnessBar: View {
    let lastUpdated: Date
    let isStale: Bool

    var body: some View {
        Label {
            if isStale {
                Text("Saved \(lastUpdated, style: .relative)")
            } else {
                Text("Updated \(lastUpdated, style: .relative)")
            }
        } icon: {
            Image(systemName: isStale ? "clock.badge.exclamationmark" : "dot.radiowaves.left.and.right")
                .foregroundStyle(isStale ? .orange : .green)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xs)
        .background(.bar)
        .accessibilityElement(children: .combine)
    }
}
