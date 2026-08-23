import SwiftUI

struct DisruptionKindPicker: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let selection: DisruptionKind
    let onSelect: (DisruptionKind) -> Void

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                accessibilityLayout
            } else if horizontalSizeClass == .regular {
                regularLayout
            } else {
                compactLayout
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    private var regularLayout: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(DisruptionKind.allCases) { kind in
                kindButton(kind)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var compactLayout: some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                kindButton(.service)
                    .frame(maxWidth: .infinity)
                kindButton(.accessibility)
                    .frame(maxWidth: .infinity)
            }

            kindButton(.stopChange)
                .frame(maxWidth: .infinity)
        }
    }

    private var accessibilityLayout: some View {
        VStack(spacing: Spacing.xs) {
            ForEach(DisruptionKind.allCases) { kind in
                kindButton(kind)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func kindButton(_ kind: DisruptionKind) -> some View {
        Button {
            onSelect(kind)
        } label: {
            kindLabel(kind)
                .font(.subheadline)
                .fontWeight(selection == kind ? .semibold : .regular)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding(.horizontal, dynamicTypeSize.isAccessibilitySize ? Spacing.lg : Spacing.md)
                .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? Spacing.sm : Spacing.none)
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(
                    selection == kind ? Color.white : DesignColor.primaryText
                )
                .background(
                    selection == kind ? DesignColor.brandDark : DesignColor.cardBackground,
                    in: .rect(cornerRadius: buttonCornerRadius)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: buttonCornerRadius, style: .continuous)
                        .stroke(
                            selection == kind ? Color.clear : DesignColor.border,
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selection == kind ? .isSelected : [])
    }

    @ViewBuilder
    private func kindLabel(_ kind: DisruptionKind) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            HStack(spacing: Spacing.md) {
                Image(systemName: kind.symbol)
                    .frame(width: 44)
                    .accessibilityHidden(true)

                Text(kind.title)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
            }
        } else {
            Label(kind.title, systemImage: kind.symbol)
        }
    }

    private var buttonCornerRadius: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? CornerRadius.lg : 1_000
    }
}
