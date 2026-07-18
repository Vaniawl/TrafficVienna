import SwiftUI

struct OnboardingView: View {
    let onGetStarted: () -> Void

    @Environment(AccountSession.self) private var accountSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step: OnboardingStep = .departures

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $step) {
                ForEach(OnboardingStep.allCases) { step in
                    OnboardingPageView(step: step)
                        .tag(step)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            VStack(spacing: Spacing.sm) {
                if step == .account {
                    OnboardingAccountAccessView()
                        .transition(Motion.stateTransition(reduceMotion: reduceMotion))
                }

                Button(action: advance) {
                    Text(buttonTitle)
                        .frame(maxWidth: .infinity)
                }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                Text(footerText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xl)
        }
        .background(DesignColor.background)
        .sensoryFeedback(.selection, trigger: step)
    }

    private var buttonTitle: LocalizedStringKey {
        guard step == .account else { return "Continue" }
        return accountSession.profile == nil ? "Continue without account" : "Start exploring"
    }

    private var footerText: LocalizedStringKey {
        step == .account
            ? "You can change your account choice later in Favourites."
            : "No account required. Your favourites stay on this device."
    }

    private func advance() {
        guard let nextStep = step.next else {
            onGetStarted()
            return
        }

        withAnimation(Motion.standard(reduceMotion: reduceMotion)) {
            step = nextStep
        }
    }
}

#Preview {
    OnboardingView(onGetStarted: {})
        .environment(AccountSession())
}
