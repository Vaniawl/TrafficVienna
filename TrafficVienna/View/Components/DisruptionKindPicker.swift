import SwiftUI

struct DisruptionKindPicker: View {
    let selection: DisruptionKind
    let onSelect: (DisruptionKind) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.xs) {
                ForEach(DisruptionKind.allCases) { kind in
                    Button {
                        onSelect(kind)
                    } label: {
                        Label(kind.title, systemImage: kind.symbol)
                            .font(.subheadline)
                            .fontWeight(selection == kind ? .semibold : .regular)
                            .padding(.horizontal, Spacing.md)
                            .frame(minHeight: 44)
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
            .padding(.horizontal, Spacing.md)
        }
        .scrollIndicators(.hidden)
    }
}
