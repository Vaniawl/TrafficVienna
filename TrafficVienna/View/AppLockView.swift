import SwiftUI

struct AppLockView: View {
    @EnvironmentObject private var appLock: AppLockStore

    var body: some View {
        ZStack {
            NeoDesign.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 82, height: 82)
                    .background(NeoDesign.heroGradient, in: RoundedRectangle(cornerRadius: 24))

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
                        .frame(minHeight: 52)
                }
                .foregroundStyle(NeoDesign.primaryActionText)
                .background(NeoDesign.primaryAction, in: Capsule())
                .buttonStyle(.plain)
                .disabled(appLock.isAuthenticating)
                .opacity(appLock.isAuthenticating ? 0.42 : 1)
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
            .background(NeoDesign.surface, in: RoundedRectangle(cornerRadius: 24))
            .overlay { RoundedRectangle(cornerRadius: 24).stroke(NeoDesign.hairline, lineWidth: 1) }
            .padding(20)
        }
    }
}
