import SwiftUI

struct AccountView: View {
    @EnvironmentObject private var auth: AuthStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingAccountRemoval = false
    @State private var removalError: String?

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
                            Text(auth.session?.provider == .apple ? "Apple ID" : "Email account")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    NavigationLink {
                        RoutinesView()
                    } label: {
                        Label("Travel routines", systemImage: "clock.arrow.2.circlepath")
                    }
                }

                Section {
                    Button("Sign out", role: .destructive) {
                        auth.signOut()
                        dismiss()
                    }
                    Button("Remove account from device", role: .destructive) {
                        showingAccountRemoval = true
                    }
                }
            }
            .navigationTitle("Account")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
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
}
