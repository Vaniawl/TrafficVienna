import SwiftUI

struct AccountToolbarButton: View {
    let action: () -> Void
    @Environment(AccountSession.self) private var accountSession

    var body: some View {
        Button(action: action) {
            Label {
                Text("Account")
            } icon: {
                ZStack {
                    Circle()
                        .fill(
                            accountSession.profile == nil
                                ? DesignColor.cardBackground
                                : DesignColor.primaryText
                        )

                    if let profile = accountSession.profile {
                        Text(profile.avatarInitial)
                            .font(.headline)
                            .foregroundStyle(DesignColor.background)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(DesignColor.primaryText)
                    }
                }
                .frame(width: 36, height: 36)
                .overlay {
                    Circle()
                        .stroke(DesignColor.border, lineWidth: 1)
                }
            }
            .labelStyle(.iconOnly)
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text("Opens account"))
        .accessibilityInputLabels([Text("Account")])
    }

    private var accessibilityLabel: String {
        guard let profile = accountSession.profile else {
            return String(localized: "Account")
        }
        return String(localized: "Account, signed in as \(profile.preferredName)")
    }
}

#Preview {
    AccountToolbarButton(action: {})
        .environment(AccountSession())
        .padding()
}
