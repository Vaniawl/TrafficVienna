import SwiftUI

struct FilterChips: View {
    let categories: [LineCategory]
    @Binding var selection: LineCategory?

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.xxs) {
                FilterChip(
                    title: String(localized: "All").uppercased(),
                    category: nil,
                    color: .appAccent,
                    selection: $selection
                )

                ForEach(categories) { category in
                    FilterChip(
                        title: category.rawValue.uppercased(),
                        category: category,
                        color: category.color,
                        selection: $selection
                    )
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .scrollIndicators(.hidden)
    }
}

#Preview {
    @Previewable @State var filter: LineCategory?
    FilterChips(categories: [.metro, .tram, .bus, .night, .sbahn], selection: $filter)
        .padding()
}
