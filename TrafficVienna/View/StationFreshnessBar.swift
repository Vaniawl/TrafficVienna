import SwiftUI

struct StationFreshnessBar: View {
    let lastUpdated: Date

    var body: some View {
        Label {
            Text("Updated \(lastUpdated, style: .relative)")
        } icon: {
            Image(systemName: "dot.radiowaves.left.and.right")
                .foregroundStyle(.green)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xs)
        .background(.bar)
        .accessibilityElement(children: .combine)
    }
}
