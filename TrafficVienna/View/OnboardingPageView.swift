import SwiftUI

struct OnboardingPageView: View {
    let step: OnboardingStep

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isPresented = false

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: dynamicTypeSize.isAccessibilitySize ? Spacing.md : Spacing.xl
            ) {
                if !dynamicTypeSize.isAccessibilitySize {
                    illustration
                }

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
            .padding(
                .vertical,
                dynamicTypeSize.isAccessibilitySize ? Spacing.md : Spacing.lg
            )
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

            Image(systemName: step.icon)
                .font(.system(size: 54, weight: .bold))
                .foregroundStyle(.white)
                .symbolEffect(.bounce, options: .nonRepeating, value: isPresented && !reduceMotion)
        }
        .aspectRatio(1.25, contentMode: .fit)
        .clipped()
        .accessibilityHidden(true)
    }
}
