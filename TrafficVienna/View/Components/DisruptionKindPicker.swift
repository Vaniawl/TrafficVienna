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
                            .bold(selection == kind)
                            .padding(.horizontal, Spacing.md)
                            .frame(minHeight: 44)
                            .foregroundStyle(selection == kind ? Color.white : Color.primary)
                            .background(
                                selection == kind ? Color.appAccent : Color.appChipBg,
                                in: Capsule()
                            )
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
