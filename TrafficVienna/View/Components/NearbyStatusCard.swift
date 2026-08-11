import SwiftUI

struct NearbyStatusCard: View {
    let icon: String?
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let actionTitle: LocalizedStringKey?
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.md) {
            if let icon {
                Label(title, systemImage: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(DesignColor.primaryText)
            } else {
                HStack(spacing: Spacing.sm) {
                    ProgressView()
                        .accessibilityHidden(true)
                    Text(title)
                }
                .font(.title3.weight(.semibold))
                .foregroundStyle(DesignColor.primaryText)
            }

            Text(message)
                .font(.body)
                .foregroundStyle(DesignColor.primaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(PremiumPrimaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .premiumSurface(elevated: true)
        .accessibilityElement(children: action == nil ? .combine : .contain)
    }
}

#Preview {
    NearbyStatusCard(
        icon: "location",
        title: "Find stops near you",
        message: "Allow location access to see live departures around you.",
        actionTitle: "Allow location",
        action: {}
    )
    .padding()
}
