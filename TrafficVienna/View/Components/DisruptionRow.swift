import SwiftUI

struct DisruptionRow: View {
    let info: TrafficInfo
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var kind: DisruptionKind {
        DisruptionKind(categoryID: info.categoryID)
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                accessibilityLayout
            } else {
                standardLayout
            }
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityLabel))
    }

    private var standardLayout: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            statusIcon

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(info.title)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)

                lineBadges

                if let description = info.description, !description.isEmpty {
                    Text(description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }

    private var accessibilityLayout: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            statusIcon

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(info.title)
                    .font(.body.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)

                lineBadges
            }
        }
    }

    private var statusIcon: some View {
        Image(systemName: kind.symbol)
            .font(.headline)
            .foregroundStyle(iconColor)
            .frame(width: 28, height: 28)
            .background(iconColor.opacity(0.12), in: Circle())
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var lineBadges: some View {
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
    }

    private var accessibilityLabel: String {
        [info.title, info.description]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: ". ")
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
