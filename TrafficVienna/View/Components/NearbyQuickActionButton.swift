import SwiftUI

struct NearbyQuickActionButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 52, height: 52)
                    .foregroundStyle(DesignColor.primaryText)
                    .background(DesignColor.cardBackground, in: Circle())
                    .accessibilityHidden(true)

                Text(title)
                    .font(.footnote)
                    .foregroundStyle(DesignColor.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .frame(minHeight: 76)
        .accessibilityLabel(Text(title))
        .accessibilityInputLabels([Text(title)])
    }
}

#Preview {
    NearbyQuickActionButton(title: "Search", systemImage: "magnifyingglass", action: {})
        .padding()
        .background(DesignColor.background)
}
