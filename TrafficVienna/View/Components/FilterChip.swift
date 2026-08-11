import SwiftUI

struct FilterChip: View {
    let title: String
    let category: LineCategory?
    let color: Color
    @Binding var selection: LineCategory?

    private var isSelected: Bool {
        selection == category
    }

    var body: some View {
        Button {
            selection = category
        } label: {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, Spacing.sm)
                .frame(minHeight: 44)
                .background(
                    isSelected ? color : DesignColor.cardBackground,
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .stroke(isSelected ? Color.clear : DesignColor.border, lineWidth: 1)
                }
                .foregroundStyle(isSelected ? .white : DesignColor.secondaryText)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}
