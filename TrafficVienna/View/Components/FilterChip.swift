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
                .bold(isSelected)
                .padding(.horizontal, Spacing.sm)
                .frame(minHeight: 44)
                .background(isSelected ? color : Color.appChipBg, in: Capsule())
                .foregroundStyle(isSelected ? .white : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}
