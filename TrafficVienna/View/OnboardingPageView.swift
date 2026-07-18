import SwiftUI

struct OnboardingPageView: View {
    let step: OnboardingStep

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
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
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.lg)
        }
        .scrollIndicators(.hidden)
        .opacity(isPresented ? 1 : 0)
        .offset(y: reduceMotion || isPresented ? 0 : 16)
        .task {
            withAnimation(Motion.standard(reduceMotion: reduceMotion)?.delay(0.08)) {
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

            Image(systemName: step.icon)
                .font(.largeTitle.scaled(by: 1.7))
                .bold()
                .foregroundStyle(.white)
                .symbolEffect(.bounce, options: .nonRepeating, value: isPresented && !reduceMotion)
        }
        .clipped()
        .accessibilityHidden(true)
    }
}
