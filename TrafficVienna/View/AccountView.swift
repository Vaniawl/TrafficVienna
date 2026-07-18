import SwiftUI

struct AccountView: View {
    @EnvironmentObject private var auth: AuthStore
    @Environment(\.dismiss) private var dismiss

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
                }
            }
            .navigationTitle("Account")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}
