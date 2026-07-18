import SwiftUI

struct NearbyStatusCard: View {
    let icon: String?
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let actionTitle: LocalizedStringKey?
    let action: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            if let icon {
                Label(title, systemImage: icon)
            } else {
                ProgressView()
                    .accessibilityHidden(true)
                Text(title)
            }
        } description: {
            Text(message)
        } actions: {
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .background(DesignColor.cardBackground, in: .rect(cornerRadius: CornerRadius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(DesignColor.border, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
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
