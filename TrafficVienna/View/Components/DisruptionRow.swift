import SwiftUI

struct DisruptionRow: View {
    let info: TrafficInfo

    private var kind: DisruptionKind {
        DisruptionKind(categoryID: info.categoryID)
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: kind.symbol)
                .font(.headline)
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.12), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(info.title)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)

                if let lines = info.relatedLines, !lines.isEmpty {
                    ScrollView(.horizontal) {
                        HStack(spacing: Spacing.xxs) {
                            ForEach(lines, id: \.self) { line in
                                LineBadge(line: line, size: .small)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }

                if let description = info.description, !description.isEmpty {
                    Text(description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
    }

    private var iconColor: Color {
        switch kind {
        case .service:
            .orange
        case .accessibility:
            .blue
        case .stopChange:
            .appAccent
        }
    }
}
