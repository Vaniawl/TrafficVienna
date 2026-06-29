import SwiftUI

struct FilterChips: View {
    let categories: [LineCategory]
    @Binding var selection: LineCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                chip(title: String(localized: "All").uppercased(), category: nil, color: .appAccent)
                ForEach(categories) { category in
                    chip(title: category.rawValue.uppercased(), category: category, color: category.color)
                }
            }
            .padding(.horizontal)
        }
    }

    private func chip(title: String, category: LineCategory?, color: Color) -> some View {
        let selected = selection == category
        return Button {
            selection = category
        } label: {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(selected ? color : Color.appChipBg, in: Capsule())
                .foregroundStyle(selected ? .white : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityLabel(selected ? "\(title), selected" : title)
    }
}

#Preview {
    @Previewable @State var filter: LineCategory? = nil
    FilterChips(categories: [.metro, .tram, .bus, .night, .sbahn], selection: $filter)
        .padding()
}
