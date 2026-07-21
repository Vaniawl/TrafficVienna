import SwiftUI

struct AccountView: View {
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var favoritesVM: FavoritesListViewModel
    @EnvironmentObject private var routines: CommuteRoutineStore
    @EnvironmentObject private var recentSearches: RecentSearchesStore
    @EnvironmentObject private var appLock: AppLockStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingAccountRemoval = false
    @State private var removalError: String?
    @State private var showingTravelDataClear = false
    @State private var showingDisplayNameEditor = false
    @State private var showingAbout = false
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

                    if auth.session?.provider == .email {
                        NavigationLink {
                            ChangePasswordView()
                        } label: {
                            Label("Change password", systemImage: "key")
                        }
                        .accessibilityIdentifier("account.changePassword")
                    }

                    NavigationLink {
                        HomeSettingsView()
                    } label: {
                        Label("Home screen", systemImage: "rectangle.grid.1x2")
                    }
                    .accessibilityIdentifier("account.homeSettings")

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

                securitySection

                Section {
                    NavigationLink {
                        PrivacyDataView()
                    } label: {
                        Label("Privacy & data", systemImage: "hand.raised")
                    }
                    .accessibilityIdentifier("account.privacyData")

                    Button {
                        showingAbout = true
                    } label: {
                        Label("About", systemImage: "info.circle")
                    }
                    .accessibilityIdentifier("account.about")
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
            .sheet(isPresented: $showingAbout) {
                AboutView()
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
            .alert("Biometric unlock", isPresented: Binding(
                get: { appLock.errorMessage != nil },
                set: { if !$0 { appLock.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { appLock.errorMessage = nil }
            } message: {
                Text(appLock.errorMessage ?? "")
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

    private var biometricUnlockBinding: Binding<Bool> {
        Binding(
            get: { appLock.isEnabled },
            set: { enabled in
                if enabled {
                    Task { await appLock.enable() }
                } else {
                    appLock.disable()
                }
            }
        )
    }

    private var appLockTimeoutBinding: Binding<AppLockTimeout> {
        Binding(
            get: { appLock.timeout },
            set: { appLock.setTimeout($0) }
        )
    }

    private var securitySection: some View {
        Section {
            Toggle(isOn: biometricUnlockBinding) {
                Label("Use \(appLock.biometricKind.title)", systemImage: "lock.shield")
            }
            .disabled(
                (appLock.biometricKind == .unavailable && !appLock.isEnabled)
                    || appLock.isAuthenticating
            )
            .accessibilityIdentifier("account.biometricUnlock")

            if appLock.isEnabled {
                Picker("Require unlock", selection: appLockTimeoutBinding) {
                    ForEach(AppLockTimeout.allCases) { timeout in
                        Text(timeout.title).tag(timeout)
                    }
                }
                .accessibilityIdentifier("account.appLockTimeout")
            }
        } header: {
            Text("Security")
        } footer: {
            Text(biometricFooter)
        }
    }

    private var biometricFooter: String {
        if appLock.biometricKind == .unavailable, appLock.isEnabled {
            return String(localized: "Biometrics changed. You can unlock with your device passcode or turn off app lock.")
        }
        if appLock.biometricKind == .unavailable {
            return String(localized: "Biometric authentication is not available on this device.")
        }
        return String(localized: "Private information is always hidden while the app is inactive. Choose when identity verification is required after returning.")
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

private struct ChangePasswordView: View {
    @EnvironmentObject private var auth: AuthStore
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmation = ""
    @State private var errorMessage: String?
    @State private var didUpdate = false
    @State private var isSubmitting = false

    var body: some View {
        Form {
            Section("Verify your account") {
                SecureField("Current password", text: $currentPassword)
                    .textContentType(.password)
                    .accessibilityIdentifier("account.currentPassword")
            }

            Section("New password") {
                SecureField("New password", text: $newPassword)
                    .textContentType(.newPassword)
                    .accessibilityIdentifier("account.newPassword")
                SecureField("Confirm new password", text: $confirmation)
                    .textContentType(.newPassword)
                    .accessibilityIdentifier("account.confirmNewPassword")

                Label("At least 8 characters", systemImage: isNewPasswordValid ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isNewPasswordValid ? .green : .secondary)
                Label("Passwords match", systemImage: passwordsMatch ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(passwordsMatch ? .green : .secondary)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("account.changePasswordError")
                }
            }

            Section {
                Button(action: updatePassword) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text("Update password")
                    }
                }
                    .frame(maxWidth: .infinity)
                    .disabled(!canSubmit)
                    .accessibilityIdentifier("account.updatePassword")
            } footer: {
                Text("Your password verifier stays in Keychain on this device.")
            }
        }
        .navigationTitle("Change password")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Password updated", isPresented: $didUpdate) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Use your new password the next time you sign in.")
        }
    }

    private var isNewPasswordValid: Bool {
        AuthStore.isValidPassword(newPassword)
    }

    private var passwordsMatch: Bool {
        AuthFormValidation.passwordsMatch(newPassword, confirmation: confirmation)
    }

    private var canSubmit: Bool {
        !isSubmitting && !currentPassword.isEmpty && isNewPasswordValid && passwordsMatch
    }

    private func updatePassword() {
        guard canSubmit else { return }
        let submittedCurrentPassword = currentPassword
        let submittedNewPassword = newPassword
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                try await auth.changePassword(
                    currentPassword: submittedCurrentPassword,
                    newPassword: submittedNewPassword
                )
                currentPassword = ""
                newPassword = ""
                confirmation = ""
                errorMessage = nil
                didUpdate = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
