import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        List {
            Section("Summary") {
                Text(
                    "Traffic Vienna does not require an account and does not use advertising, analytics, or tracking."
                )
            }

            Section("Location") {
                Text(
                    "If you allow location access, your location is used only on your device to find nearby stops. It is not stored or sent to the transport data provider."
                )
            }

            Section("On-device data") {
                Text(
                    "Favourites, recent searches, onboarding state, widget preferences, and departure reminders stay on your device or in the app’s shared widget container."
                )
            }

            Section("Notifications") {
                Text(
                    "If you create a departure reminder, Traffic Vienna asks iOS to deliver a local notification on this device. Reminder details are not sent to Traffic Vienna or to a push-notification server. You can cancel reminders in the app or revoke notification access in Settings."
                )
            }

            Section("Live transport data") {
                Text(
                    "To refresh departures and alerts, the app sends station or route identifiers to Wiener Linien over HTTPS. Wiener Linien receives technical connection data, such as an IP address, under its own privacy terms. Traffic Vienna does not operate a backend or receive those server logs."
                )
            }

            Section("Your choices") {
                Text(
                    "You can remove favourites, recent searches, and departure reminders in the app. Deleting the app removes its local app and widget data."
                )
            }

            Section("Contact") {
                if let supportURL = URL(
                    string: "https://github.com/Vaniawl/TrafficVienna/issues"
                ) {
                    Link(destination: supportURL) {
                        Label("Support and privacy questions", systemImage: "safari")
                    }
                }
            }

            Section {
                Text("Last updated: 30 July 2026")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
