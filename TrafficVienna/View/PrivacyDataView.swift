import SwiftUI

struct PrivacyDataView: View {
    var body: some View {
        List {
            Section {
                privacyRow(
                    icon: "person.badge.key",
                    title: "Identity",
                    description: "Email password verifiers stay in Keychain on this device. Sign in with Apple uses Apple’s system authentication service. Traffic Vienna has no account server."
                )
            } header: {
                Text("Your account")
            } footer: {
                Text("Email accounts and preferences do not sync between devices.")
            }

            Section("Location") {
                privacyRow(
                    icon: "location",
                    title: "Used only when needed",
                    description: "Location access is optional and helps find nearby stops. Traffic Vienna does not save your coordinates or send them with transit requests."
                )
            }

            Section("On this device") {
                privacyRow(
                    icon: "iphone",
                    title: "Travel preferences",
                    description: "Favourites, recent searches, routines, appearance, and widget state are stored locally in the app or its shared widget container."
                )
            }

            Section("Network requests") {
                privacyRow(
                    icon: "network",
                    title: "Wiener Linien live data",
                    description: "Traffic Vienna requests departures and service alerts over HTTPS using public stop identifiers. Wiener Linien can observe the request’s source IP address."
                )
            }

            Section {
                privacyRow(
                    icon: "hand.raised",
                    title: "No advertising or tracking",
                    description: "Traffic Vienna contains no ads, analytics, or tracking SDKs."
                )
            }
        }
        .navigationTitle("Privacy & data")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("privacyData.screen")
    }

    private func privacyRow(
        icon: String,
        title: LocalizedStringKey,
        description: LocalizedStringKey
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(.tint)
                .frame(width: 28, height: 28)
                .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        PrivacyDataView()
    }
}
