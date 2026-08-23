import SwiftUI

struct DisruptionDetailView: View {
    let info: TrafficInfo

    private var kind: DisruptionKind {
        DisruptionKind(categoryID: info.categoryID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                Label(kind.title, systemImage: kind.symbol)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignColor.accentText)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(DesignColor.brand.opacity(0.12), in: Capsule())

                Text(info.title)
                    .font(.title2)
                    .bold()
                    .foregroundStyle(DesignColor.primaryText)

                if let lines = info.relatedLines, !lines.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Affected lines")
                            .font(.headline)

                        ScrollView(.horizontal) {
                            HStack(spacing: Spacing.xs) {
                                ForEach(lines, id: \.self) { line in
                                    LineBadge(line: line)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                }

                if let description = info.description, !description.isEmpty {
                    Text(description)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .premiumSurface()
                }

                LabeledContent("Source", value: "Wiener Linien")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.xl)
        }
        .navigationTitle("Alert details")
        .navigationBarTitleDisplayMode(.inline)
        .background(DesignColor.background)
    }
}
