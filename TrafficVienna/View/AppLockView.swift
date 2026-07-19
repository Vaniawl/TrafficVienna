import SwiftUI

struct AppLockView: View {
    @EnvironmentObject private var appLock: AppLockStore

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0xE20917).opacity(0.22), Color(.systemBackground), Color.indigo.opacity(0.14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 82, height: 82)
                    .background(Color(hex: 0xE20917).gradient, in: RoundedRectangle(cornerRadius: 26))

                VStack(spacing: 8) {
                    Text("Traffic Vienna is locked")
                        .font(.title2.bold())
                    Text("Unlock to see your departures and saved travel data.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await appLock.unlock() }
                } label: {
                    Label(
                        "Unlock with \(appLock.biometricKind.title)",
                        systemImage: appLock.biometricKind.symbolName
                    )
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: 0xE20917))
                .disabled(appLock.isAuthenticating)
                .accessibilityIdentifier("appLock.unlock")

                if let errorMessage = appLock.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("appLock.error")
                }
            }
            .padding(28)
            .frame(maxWidth: 460)
        }
    }
}
