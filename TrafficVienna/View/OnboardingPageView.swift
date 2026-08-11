import SwiftUI

struct OnboardingPageView: View {
    let step: OnboardingStep

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xxl) {
                illustration

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(step.eyebrow)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignColor.accentText)

                    Text(step.title)
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(DesignColor.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(step.message)
                        .font(.title3)
                        .foregroundStyle(DesignColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.lg)
        }
        .scrollIndicators(.hidden)
        .opacity(isPresented ? 1 : 0)
        .offset(y: reduceMotion || isPresented ? 0 : 16)
        .task {
            withAnimation(Motion.standard(reduceMotion: reduceMotion)?.delay(0.08)) {
                isPresented = true
            }
        }
        .accessibilityIdentifier("onboarding-page-\(step.rawValue)")
        .accessibilityElement(children: .combine)
    }

    private var illustration: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .fill(DesignColor.brandGradient)
                .aspectRatio(1.12, contentMode: .fit)

            Circle()
                .fill(.white.opacity(0.11))
                .frame(width: 230, height: 230)
                .offset(x: 145, y: -92)

            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack {
                    Image(systemName: step.icon)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(DesignColor.brandDark)
                        .frame(width: 58, height: 58)
                        .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: CornerRadius.md))

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(step.eyebrow)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.78))

                    Text(step.title)
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Capsule()
                        .fill(.white.opacity(0.28))
                        .frame(width: 118, height: 8)
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: CornerRadius.lg))
            }
            .padding(Spacing.lg)

        }
        .clipped()
        .shadow(
            color: Shadow.lg.color,
            radius: Shadow.lg.radius,
            x: Shadow.lg.x,
            y: Shadow.lg.y
        )
        .symbolEffect(.bounce, options: .nonRepeating, value: isPresented && !reduceMotion)
        .accessibilityHidden(true)
    }
}
