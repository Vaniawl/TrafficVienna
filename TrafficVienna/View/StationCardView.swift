//
//  StationCardView.swift
//  TrafficVienna
//
//  Presentational station card for the Nearby tab: name + walking time in the
//  header, then the next departures per line. Data is provided by NearbyViewModel.
//

import SwiftUI

struct StationCardView: View {
    let station: Station
    var distance: Double?
    var lines: [Lines] = []
    var failed: Bool = false
    var updatedAt: Date? = nil
    var isStale = false

    private let maxLines = 4

    private var walkMinutes: Int? {
        guard let distance else { return nil }
        return max(1, Int((distance / walkingSpeed).rounded()))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            header
            content
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignColor.cardBackground,
                    in: RoundedRectangle(cornerRadius: CornerRadius.lg))
        .shadow(color: Shadow.md.color,
                radius: Shadow.md.radius,
                x: Shadow.md.x,
                y: Shadow.md.y)
        .contentShape(.rect(cornerRadius: CornerRadius.lg))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(stationAccessibilityLabel)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(station.name)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                if !lines.isEmpty {
                    let unique = Set(lines.map(\.name)).sorted()
                    HStack(spacing: Spacing.xxs) {
                        ForEach(unique, id: \.self) { name in
                            LineBadge(line: name, size: .small)
                                .accessibilityLabel("Line \(name)")
                        }
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                if let distance {
                    Label(walkText(distance), systemImage: "figure.walk")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Walking distance")
                }
                if let updatedAt {
                    if isStale {
                        Label("Saved data", systemImage: "clock.badge.exclamationmark")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .accessibilityLabel("Saved data from \(RelativeTime.updated(since: updatedAt))")
                    } else {
                        Text(updatedText(updatedAt))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .accessibilityLabel("Updated \(RelativeTime.updated(since: updatedAt))")
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Station \(station.name), \(walkTextForAccessibility)")
    }

    @ViewBuilder
    private var content: some View {
        if station.diva == nil {
            noLiveDataView
        } else if !lines.isEmpty {
            let visible = Array(lines.prefix(maxLines).enumerated())
            VStack(spacing: 0) {
                ForEach(visible, id: \.offset) { index, line in
                    DepartureLineRow(
                        lineName: line.name,
                        destination: line.towards,
                        minutes: line.departures.departure.map { $0.departureTime.liveMinutes },
                        walkMinutes: walkMinutes,
                        nextIsLive: line.departures.departure.first?.departureTime.timeReal != nil,
                        showFollowUp: false
                    )
                    .padding(.vertical, Spacing.xs)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Line \(line.name) to \(line.towards)")
                    if index < visible.count - 1 { Divider() }
                }
            }
        } else if failed {
            errorMessageView
        } else {
            skeleton
        }
    }

    private var noLiveDataView: some View {
        label("No live data for this stop")
            .accessibilityLabel("No live data for this stop")
    }

    private var errorMessageView: some View {
        label("Couldn't load departures", color: .orange)
            .accessibilityLabel("Couldn't load departures. Try again.")
    }

    // Placeholder rows shown while the first load is in flight.
    private var skeleton: some View {
        VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { index in
                DepartureLineRow(lineName: "00", destination: "Loading station", minutes: [0, 0])
                    .padding(.vertical, Spacing.xs)
                if index < 2 { Divider() }
            }
        }
        .redacted(reason: .placeholder)
        .shimmer()
    }

    private func label(_ text: String, color: Color = .secondary) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(color)
            .padding(.vertical, Spacing.xs)
    }

    private var stationAccessibilityLabel: String {
        let walkText = walkMinutes.map { "Walking approximately \($0) minutes" } ?? "Distance unknown"
        let linesText = lines.isEmpty ? "No departures loaded" : "Departures available"
        let freshness = isStale ? "Showing saved data." : ""
        return "\(station.name). \(walkText). \(linesText). \(freshness)"
    }

    private var walkTextForAccessibility: String {
        guard let distance else { return "" }
        let walkMin = max(1, Int((distance / walkingSpeed).rounded()))
        let dist = distance < 1000 ? "\(Int(distance)) meters" : String(format: "%.1f kilometers", distance / 1000)
        return "Walking approximately \(walkMin) minutes, \(dist) away"
    }

    private func walkText(_ meters: Double) -> String {
        let walkMin = max(1, Int((meters / walkingSpeed).rounded()))
        let dist = meters < 1000 ? "\(Int(meters)) m" : String(format: "%.1f km", meters / 1000)
        return "\(walkMin) min · \(dist)"
    }

    private func updatedText(_ date: Date) -> String {
        RelativeTime.updated(since: date)
    }
}

#Preview {
    StationCardView(
        station: Station(id: 1, diva: 60201435, name: "Karlsplatz",
                         lat: 48.200832, lon: 16.369505),
        distance: 280,
        lines: []
    )
    .padding()
    .background(DesignColor.cardBackground)
}
