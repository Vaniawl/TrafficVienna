import SwiftUI

struct AccountView: View {
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var favoritesVM: FavoritesListViewModel
    @EnvironmentObject private var routines: CommuteRoutineStore
    @EnvironmentObject private var recentSearches: RecentSearchesStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingAccountRemoval = false
    @State private var removalError: String?
    @State private var showingTravelDataClear = false
    @State private var showingDisplayNameEditor = false
    @State private var displayNameDraft = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: auth.session?.provider == .apple ? "apple.logo" : "person.crop.circle.fill")
                            .font(.system(size: 34))
                            .frame(width: 56, height: 56)
                            .background(.quaternary, in: Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text(auth.session?.displayName ?? auth.session?.email ?? "Traffic Vienna user")
                                .font(.headline)
                            if auth.session?.displayName != nil, let email = auth.session?.email {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Text(auth.session?.provider == .apple ? "Apple ID" : "Email account")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    Button {
                        displayNameDraft = auth.session?.displayName ?? ""
                        showingDisplayNameEditor = true
                    } label: {
                        Label("Edit display name", systemImage: "person.text.rectangle")
                    }
                    .accessibilityIdentifier("account.editDisplayName")

                    NavigationLink {
                        AppearanceView()
                    } label: {
                        Label("Appearance", systemImage: "paintpalette")
                    }
                    .accessibilityIdentifier("account.appearance")

                    NavigationLink {
                        RoutinesView()
                    } label: {
                        Label("Travel routines", systemImage: "clock.arrow.2.circlepath")
                    }

                    NavigationLink {
                        DepartureRemindersView()
                    } label: {
                        Label("Departure reminders", systemImage: "bell.badge")
                    }
                    .accessibilityIdentifier("account.departureReminders")

                    NavigationLink {
                        LiveActivitiesView()
                    } label: {
                        Label("Live Activities", systemImage: "dot.radiowaves.left.and.right")
                    }
                    .accessibilityIdentifier("account.liveActivities")
                }

                Section {
                    Button("Sign out", role: .destructive) {
                        auth.signOut()
                        dismiss()
                    }
                    Button("Remove account from device", role: .destructive) {
                        showingAccountRemoval = true
                    }
                    Button("Clear travel data", role: .destructive) {
                        showingTravelDataClear = true
                    }
                }
            }
            .navigationTitle("Account")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .alert("Edit display name", isPresented: $showingDisplayNameEditor) {
                TextField("Display name", text: $displayNameDraft)
                    .textContentType(.name)
                    .accessibilityIdentifier("account.displayNameField")
                Button("Save") { auth.updateDisplayName(displayNameDraft) }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog(
                "Remove account from device",
                isPresented: $showingAccountRemoval,
                titleVisibility: .visible
            ) {
                Button("Remove account", role: .destructive) { removeAccount() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(accountRemovalMessage)
            }
            .alert("Couldn’t remove account", isPresented: Binding(
                get: { removalError != nil },
                set: { if !$0 { removalError = nil } }
            )) {
                Button("OK", role: .cancel) { removalError = nil }
            } message: {
                Text(removalError ?? "")
            }
            .confirmationDialog(
                "Clear travel data",
                isPresented: $showingTravelDataClear,
                titleVisibility: .visible
            ) {
                Button("Clear data", role: .destructive) { clearTravelData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes favourites, routines, recent searches, departure reminders, Live Activities, widget data, and cached departures. Your sign-in stays active.")
            }
        }
    }

    private var accountRemovalMessage: String {
        if auth.session?.provider == .apple {
            return String(localized: "This removes the Apple sign-in session from this device. It does not delete or revoke your Apple ID. Your saved stations and routines remain.")
        }
        return String(localized: "This deletes the local email password verifier and signs you out. Your saved stations and routines remain on this device.")
    }

    private func removeAccount() {
        do {
            try auth.removeCurrentAccountFromDevice()
            dismiss()
        } catch {
            removalError = error.localizedDescription
        }
    }

    private func clearTravelData() {
        favoritesVM.clearTravelFavorites()
        routines.removeAll()
        recentSearches.clear()
        TravelDataResetService().clearAuxiliaryData()
        Task {
            await DepartureReminderScheduler.removeAllScheduled()
            await LiveActivityController.stopAll()
            await MonitorService.shared.clearCache()
        }
    }
}
