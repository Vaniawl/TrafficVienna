import SwiftUI

struct DisruptionKindPicker: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let selection: DisruptionKind
    let onSelect: (DisruptionKind) -> Void

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
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

    private func kindButton(_ kind: DisruptionKind) -> some View {
        Button {
            onSelect(kind)
        } label: {
            Label(kind.title, systemImage: kind.symbol)
                .font(.subheadline)
                .fontWeight(selection == kind ? .semibold : .regular)
                .padding(.horizontal, Spacing.md)
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(
                    selection == kind ? Color.white : DesignColor.primaryText
                )
                .background(
                    selection == kind ? DesignColor.brandDark : DesignColor.cardBackground,
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .stroke(
                            selection == kind ? Color.clear : DesignColor.border,
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selection == kind ? .isSelected : [])
    }
}
