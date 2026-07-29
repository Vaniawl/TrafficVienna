import SwiftUI

struct OnboardingView: View {
    let onGetStarted: () -> Void

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
                Button(action: advance) {
                    Text(step.next == nil ? "Start exploring" : "Continue")
                        .frame(maxWidth: .infinity)
                }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                Text("No account required. Your favourites stay on this device.")
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
}
