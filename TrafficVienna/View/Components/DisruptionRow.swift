//
//  DisruptionRow.swift
//  TrafficVienna
//
//  A single service disruption / notice: title, affected line badges and an
//  expandable description.
//

import SwiftUI

struct DisruptionRow: View {
    let info: TrafficInfo
    @State private var expanded = false

    private var hasLongDescription: Bool {
        (info.description?.count ?? 0) > 90
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.subheadline)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(info.title)
                        .font(.subheadline.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)

                    if let lines = info.relatedLines, !lines.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.xxs) {
                                ForEach(lines, id: \.self) { LineBadge(line: $0, size: .small) }
                            }
                        }
                    }

                    if let description = info.description, !description.isEmpty {
                        Text(description)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(expanded ? nil : 2)
                            .fixedSize(horizontal: false, vertical: true)

                        if hasLongDescription {
                            Text(expanded ? "Show less" : "Show more")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if hasLongDescription { withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() } }
        }
        .padding(.vertical, Spacing.xxs)
    }
}

#Preview {
    List {
        DisruptionRow(info: TrafficInfo(
            name: "I1",
            title: "9, 40, 41, 42: Gleisbauarbeiten",
            description: "Linie 42: Derzeit ist ein Betrieb nicht möglich. Zwischen Währinger Straße und Gersthof fährt der Ersatzbus 41E. Voraussichtliche Dauer: bis 27.06.2026.",
            priority: "1",
            relatedLines: ["9", "40", "41", "42"]
        ))
    }
}
