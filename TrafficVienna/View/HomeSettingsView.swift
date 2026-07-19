import SwiftUI

struct HomeSettingsView: View {
    @EnvironmentObject private var preferences: HomePreferences

    var body: some View {
        Form {
            Section {
                ForEach(preferences.moduleOrder) { module in
                    Toggle(isOn: visibilityBinding(for: module)) {
                        moduleLabel(for: module)
                    }
                    .accessibilityIdentifier("homeSettings.\(module.rawValue)")
                }
                .onMove(perform: preferences.moveModules)
            } header: {
                Text("Home modules")
            } footer: {
                Text("Drag modules in Edit mode to choose their order. Hidden modules keep their data.")
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
        .toolbar {
            EditButton()
                .accessibilityIdentifier("homeSettings.edit")
        }
    }

    private func visibilityBinding(for module: HomeModule) -> Binding<Bool> {
        Binding(
            get: { preferences.isVisible(module) },
            set: { preferences.setVisible($0, for: module) }
        )
    }

    private func moduleLabel(for module: HomeModule) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(title(for: module))
                Text(subtitle(for: module))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: icon(for: module))
                .foregroundStyle(.tint)
        }
    }

    private func title(for module: HomeModule) -> LocalizedStringKey {
        switch module {
        case .savedStations: "Saved stations"
        case .savedRoutes: "Saved routes"
        case .smartInsight: "Smart insight"
        }
    }

    private func subtitle(for module: HomeModule) -> LocalizedStringKey {
        switch module {
        case .savedStations: "Quick access to your favourite stops"
        case .savedRoutes: "Live departures for your favourite lines"
        case .smartInsight: "Relevant alerts, routines, and updates"
        }
    }

    private func icon(for module: HomeModule) -> String {
        switch module {
        case .savedStations: "star.fill"
        case .savedRoutes: "tram.fill"
        case .smartInsight: "bolt.fill"
        }
    }
}

#Preview {
    NavigationStack { HomeSettingsView() }
        .environmentObject(HomePreferences())
}
