import SwiftUI

struct HomeSettingsView: View {
    @EnvironmentObject private var preferences: HomePreferences

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $preferences.showsSavedStations) {
                    moduleLabel(
                        title: "Saved stations",
                        subtitle: "Quick access to your favourite stops",
                        icon: "star.fill"
                    )
                }
                .accessibilityIdentifier("homeSettings.savedStations")

                Toggle(isOn: $preferences.showsSavedRoutes) {
                    moduleLabel(
                        title: "Saved routes",
                        subtitle: "Live departures for your favourite lines",
                        icon: "tram.fill"
                    )
                }
                .accessibilityIdentifier("homeSettings.savedRoutes")

                Toggle(isOn: $preferences.showsSmartInsight) {
                    moduleLabel(
                        title: "Smart insight",
                        subtitle: "Relevant alerts, routines, and updates",
                        icon: "bolt.fill"
                    )
                }
                .accessibilityIdentifier("homeSettings.smartInsight")
            } header: {
                Text("Home modules")
            } footer: {
                Text("Hidden modules keep their data and can be shown again at any time.")
            }

            Section {
                Button("Restore default layout") {
                    preferences.restoreDefaults()
                }
                .disabled(preferences.isDefault)
                .accessibilityIdentifier("homeSettings.restoreDefaults")
            }
        }
        .navigationTitle("Home screen")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func moduleLabel(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        icon: String
    ) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(.tint)
        }
    }
}

#Preview {
    NavigationStack { HomeSettingsView() }
        .environmentObject(HomePreferences())
}
