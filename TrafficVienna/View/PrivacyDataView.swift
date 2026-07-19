import SwiftUI
import UniformTypeIdentifiers

struct PrivacyDataView: View {
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var favorites: FavoritesListViewModel
    @EnvironmentObject private var routines: CommuteRoutineStore
    @EnvironmentObject private var recentSearches: RecentSearchesStore
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var homePreferences: HomePreferences
    @EnvironmentObject private var appLock: AppLockStore
    @State private var exportDocument: TravelDataExportDocument?
    @State private var isExporting = false
    @State private var exportError: String?

    var body: some View {
        List {
            Section {
                privacyRow(
                    icon: "person.badge.key",
                    title: "Identity",
                    description: "Email password verifiers stay in Keychain on this device. Sign in with Apple uses Apple’s system authentication service. Traffic Vienna has no account server."
                )
                privacyRow(
                    icon: "lock.shield",
                    title: "Biometric app lock",
                    description: "Face ID, Touch ID, or Optic ID is verified by the system. Traffic Vienna never receives or stores your biometric data."
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

            Section {
                privacyRow(
                    icon: "iphone",
                    title: "Travel preferences",
                    description: "Favourites, recent searches, routines, appearance, and widget state are stored locally in the app or its shared widget container."
                )

                Button(action: prepareExport) {
                    Label("Export my data", systemImage: "square.and.arrow.up")
                }
                .accessibilityIdentifier("privacyData.export")
            } header: {
                Text("On this device")
            } footer: {
                Text("The export includes your profile details and saved travel preferences. It never includes passwords, authentication tokens, live-data caches, or your location history.")
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
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "TrafficVienna-data"
        ) { result in
            if case .failure(let error) = result {
                exportError = error.localizedDescription
            }
            exportDocument = nil
        }
        .alert("Couldn’t export data", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("OK", role: .cancel) { exportError = nil }
        } message: {
            Text(exportError ?? "")
        }
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

    private func prepareExport() {
        let export = TravelDataExport(
            session: auth.session,
            preferences: TravelDataExport.Preferences(
                appearance: theme.preset.rawValue,
                visibleHomeModules: homePreferences.moduleOrder
                    .filter(homePreferences.isVisible)
                    .map(\.rawValue),
                homeModuleOrder: homePreferences.moduleOrder.map(\.rawValue),
                appLockEnabled: appLock.isEnabled,
                appLockTimeoutSeconds: appLock.timeout.rawValue
            ),
            favoriteStations: favorites.stations,
            favoriteRoutes: favorites.favoriteRoutes,
            routines: routines.routines,
            recentStationIDs: recentSearches.ids
        )
        do {
            exportDocument = try TravelDataExportDocument(export: export)
            isExporting = true
        } catch {
            exportError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        PrivacyDataView()
    }
    .environmentObject(AuthStore())
    .environmentObject(FavoritesListViewModel())
    .environmentObject(CommuteRoutineStore())
    .environmentObject(RecentSearchesStore())
    .environmentObject(ThemeManager())
    .environmentObject(HomePreferences())
    .environmentObject(AppLockStore())
}
