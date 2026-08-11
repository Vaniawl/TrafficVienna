import SwiftUI

struct StationFreshnessBar: View {
    let lastUpdated: Date
    let isStale: Bool

    var body: some View {
        Label {
            if isStale {
                Text("Saved \(relativeTimestamp)")
            } else {
                Text("Updated \(relativeTimestamp)")
            }
        } icon: {
            Image(systemName: isStale ? "clock.badge.exclamationmark" : "dot.radiowaves.left.and.right")
                .foregroundStyle(isStale ? DesignColor.warning : DesignColor.success)
        }
        .font(.footnote)
        .foregroundStyle(DesignColor.secondaryText)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(DesignColor.elevatedBackground)
        .overlay(alignment: .top) {
            Divider().overlay(DesignColor.border)
        }
        .accessibilityElement(children: .combine)
    }

    private var relativeTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUpdated, relativeTo: Date())
    }
}
