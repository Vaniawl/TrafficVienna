//
//  StationCardView.swift
//  TrafficVienna
//
//  Presentational station card for the Nearby tab: name + walking time in the
//  header, then the next departures per line. Data is provided by NearbyViewModel.
//

import SwiftUI

struct StationCardView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let station: Station
    var distance: Double?
    var lines: [Lines] = []
    var failed: Bool = false
    var updatedAt: Date? = nil

    private let maxLines = 4

    private var walkMinutes: Int? {
        guard let distance else { return nil }
        return max(1, Int((distance / walkingSpeed).rounded()))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: cardCornerRadius))
        .shadow(color: themeManager.preset.cardStyle == .elevated ? .black.opacity(0.06) : .clear,
                radius: 8, y: 2)
        .contentShape(.rect(cornerRadius: cardCornerRadius))
    }

    private var cardCornerRadius: CGFloat {
        themeManager.preset.cardStyle == .elevated ? 14 : 16
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(station.name)
                    .font(.headline)
                if !lines.isEmpty {
                    let unique = Set(lines.map(\.name)).sorted()
                    HStack(spacing: 3) {
                        ForEach(unique, id: \.self) { name in
                            LineBadge(line: name, size: .small)
                        }
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if let distance {
                    Label(walkText(distance), systemImage: "figure.walk")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let updatedAt {
                    Text(updatedText(updatedAt))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if station.diva == nil {
            label("No live data for this stop")
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
                    .padding(.vertical, 8)
                    if index < visible.count - 1 { Divider() }
                }
            }
        } else if failed {
            label("Couldn’t load departures")
        } else {
            skeleton
        }
    }

    // Placeholder rows shown while the first load is in flight.
    private var skeleton: some View {
        VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { index in
                DepartureLineRow(lineName: "00", destination: "Loading station", minutes: [0, 0])
                    .padding(.vertical, 8)
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
            .padding(.vertical, 4)
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
    .background(Color(.systemGroupedBackground))
}
