import SwiftUI

struct OnboardingPageView: View {
    let step: OnboardingStep

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            Spacer(minLength: Spacing.lg)

            illustration

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(step.eyebrow)
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.appAccent)

                Text(step.title)
                    .font(.largeTitle)
                    .bold()
                    .fixedSize(horizontal: false, vertical: true)

                Text(step.message)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: Spacing.xl)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.lg)
        .opacity(isPresented ? 1 : 0)
        .offset(y: reduceMotion || isPresented ? 0 : 16)
        .task {
            withAnimation(reduceMotion ? nil : .smooth.delay(0.08)) {
                isPresented = true
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var illustration: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .fill(DesignColor.brandGradient)
                .aspectRatio(1.25, contentMode: .fit)

            Circle()
                .fill(.white.opacity(0.14))
                .frame(width: 180, height: 180)
                .offset(x: 90, y: -70)

            Image(systemName: step.icon)
                .font(.system(size: 68, weight: .semibold))
                .foregroundStyle(.white)
                .symbolEffect(.bounce, options: .nonRepeating, value: isPresented && !reduceMotion)
        }
        .clipped()
        .accessibilityHidden(true)
    }
}
