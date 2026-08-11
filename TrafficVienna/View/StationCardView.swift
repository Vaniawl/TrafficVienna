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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
        .premiumSurface(elevated: true)
        .contentShape(.rect(cornerRadius: CornerRadius.lg))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(stationAccessibilityLabel)
    }

    private var header: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    stationIdentity
                    stationMetadata(alignment: .leading)
                }
            } else {
                HStack(alignment: .top, spacing: Spacing.sm) {
                    stationIdentity
                    Spacer()
                    stationMetadata(alignment: .trailing)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Station \(station.name), \(walkTextForAccessibility)")
    }

    private var stationIdentity: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(station.name)
                .font(
                    dynamicTypeSize.isAccessibilitySize
                        ? .body.weight(.semibold)
                        : .headline.weight(.semibold)
                )
                .foregroundStyle(DesignColor.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            if !uniqueLineNames.isEmpty {
                if dynamicTypeSize.isAccessibilitySize {
                        Text(verbatim: uniqueLineNames.joined(separator: ", "))
                            .font(.body.weight(.semibold))
                            .foregroundStyle(DesignColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    HStack(spacing: Spacing.xxs) {
                        ForEach(uniqueLineNames, id: \.self) { name in
                            LineBadge(line: name, size: .small)
                                .accessibilityLabel("Line \(name)")
                        }
                    }
                }
            }
        }
    }

    private func stationMetadata(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: Spacing.xxs) {
            if let distance {
                Label(walkText(distance), systemImage: "figure.walk")
                    .font(.caption)
                    .foregroundStyle(DesignColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Walking distance")
            }
            if let updatedAt {
                if isStale {
                    Label("Saved data", systemImage: "clock.badge.exclamationmark")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Saved data from \(RelativeTime.updated(since: updatedAt))")
                } else {
                    Text(updatedText(updatedAt))
                        .font(.caption)
                        .foregroundStyle(DesignColor.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Updated \(RelativeTime.updated(since: updatedAt))")
                }
            }
        }
    }

    private var uniqueLineNames: [String] {
        Set(lines.map(\.name)).sorted()
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
                    if index < visible.count - 1 {
                        Divider().overlay(DesignColor.separator)
                    }
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
                if index < 2 {
                    Divider().overlay(DesignColor.separator)
                }
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
        let walkText = walkMinutes.map {
            String(localized: "Walking approximately \($0) minutes")
        } ?? String(localized: "Distance unknown")
        let linesText = lines.isEmpty
            ? String(localized: "No departures loaded")
            : String(localized: "Departures available")
        let freshness = isStale ? String(localized: "Showing saved data.") : ""
        return "\(station.name). \(walkText). \(linesText). \(freshness)"
    }

    private var walkTextForAccessibility: String {
        guard let distance else { return "" }
        let walkMin = max(1, Int((distance / walkingSpeed).rounded()))
        let measurement = distance < 1000
            ? Measurement(value: distance.rounded(), unit: UnitLength.meters)
            : Measurement(value: distance / 1000, unit: UnitLength.kilometers)
        let distanceText = measurement.formatted(.measurement(width: .wide))
        return String(localized: "Walking approximately \(walkMin) minutes, \(distanceText) away")
    }

    private func walkText(_ meters: Double) -> String {
        let walkMin = max(1, Int((meters / walkingSpeed).rounded()))
        let kilometers = (meters / 1000).formatted(.number.precision(.fractionLength(1)))
        let dist = meters < 1000 ? "\(Int(meters)) m" : "\(kilometers) km"
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
