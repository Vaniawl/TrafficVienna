//
//  TrafficViennaWidget.swift
//  TrafficViennaWidget
//
//  Created by Ivan Dovhosheia on 23.11.25.
//

import WidgetKit
import SwiftUI
import AppIntents
import ActivityKit

struct SimpleEntry: TimelineEntry {
    let date: Date
    let items: [WidgetDepartureData] // up to 3
    let lastUpdated: Date?
}
// Shared constants and keys
private let appGroupID = "group.wellbe.TrafficVienna"
private let widgetKind = "TrafficViennaWidget"
private let widgetDataKey = "widget_departure"
private let widgetLastUpdatedKey = "widget_last_updated"
private let widgetLastFetchAttemptKey = "widget_last_fetch_attempt"
private let widgetRefreshRequestedKey = "widget_refresh_requested_at"

private let favoritesKey = "favorite_routes"

private struct FavoriteStationGroup {
    let diva: Int
    var favourites: [FavoriteRoute]
}

// DTOs for decoding monitor response inside the widget target
private struct MonitorResponse: Decodable { let data: DataBlock }
private struct DataBlock: Decodable { let monitors: [Monitor] }
private struct Monitor: Decodable { let locationStop: LocationStop?; let lines: [Lines] }
private struct LocationStop: Decodable { let properties: StopProperties }
private struct StopProperties: Decodable { let title: String }
private struct Lines: Decodable { let name: String; let towards: String; let departures: Departures }
private struct Departures: Decodable { let departure: [Departure] }
private struct Departure: Decodable { let departureTime: DepartureTime }
private struct DepartureTime: Decodable { let countdown: Int }

// Local network fetcher for widget
private func fetchMonitorData(diva: Int, includeArea: Bool) async throws -> MonitorResponse {
    var urlString = "https://www.wienerlinien.at/ogd_realtime/monitor?diva=\(diva)"
    if includeArea { urlString += "&aArea=1" }
    guard let url = URL(string: urlString) else { throw URLError(.badURL) }
    var request = URLRequest(url: url)
    request.timeoutInterval = 12
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }
    return try JSONDecoder().decode(MonitorResponse.self, from: data)
}

private func loadFavoritesFromDefaults() -> [FavoriteRoute] {
    let defaults = UserDefaults(suiteName: appGroupID)
    guard let data = defaults?.data(forKey: favoritesKey),
          let decoded = try? JSONDecoder().decode(Set<FavoriteRoute>.self, from: data)
    else { return [] }
    return decoded.sorted()
}

struct Provider: AppIntentTimelineProvider {
    // Preview
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: .now,
            items: [
                WidgetDepartureData(lineName: "U1", stopName: "Stephansplatz", destination: "Leopoldau", departures: [2,7,12]),
                WidgetDepartureData(lineName: "O", stopName: "Praterstern", destination: "Migerka", departures: [3,9,14])
            ],
            lastUpdated: .now
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let (items, lastUpdated) = loadCached()
        if items.isEmpty {
            return placeholder(in: context)
        } else {
            let now = Date.now
            return SimpleEntry(
                date: now,
                items: WidgetCountdownProjection.items(
                    items,
                    fallbackUpdatedAt: lastUpdated,
                    at: now
                ),
                lastUpdated: lastUpdated
            )
        }
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let defaults = UserDefaults(suiteName: appGroupID)
        let now = Date.now
        let lastAttempt = defaults?.object(forKey: widgetLastFetchAttemptKey) as? Date ?? .distantPast
        let refreshRequestedAt = defaults?.object(forKey: widgetRefreshRequestedKey) as? Date
        let hasManualRefresh = refreshRequestedAt.map { $0 > lastAttempt } ?? false
        let canFetch = hasManualRefresh || now.timeIntervalSince(lastAttempt) >= 300

        var (items, lastUpdated) = loadCached()

        if canFetch {
            defaults?.set(now, forKey: widgetLastFetchAttemptKey)
            if let refresh = await fetchFavoritesData(cached: items) {
                items = refresh.items
                if refresh.isComplete {
                    lastUpdated = now
                }
                saveCached(items: items, lastUpdated: lastUpdated)
            }
        }

        let entries = (0..<5).map { minute in
            let entryDate = now.addingTimeInterval(TimeInterval(minute * 60))
            return SimpleEntry(
                date: entryDate,
                items: WidgetCountdownProjection.items(
                    items,
                    fallbackUpdatedAt: lastUpdated,
                    at: entryDate
                ),
                lastUpdated: lastUpdated
            )
        }
        return Timeline(entries: entries, policy: .after(now.addingTimeInterval(5 * 60)))
    }

    // MARK: - Cache helpers
    private func loadCached() -> ([WidgetDepartureData], Date?) {
        let defaults = UserDefaults(suiteName: appGroupID)
        var items: [WidgetDepartureData] = []
        var last: Date? = nil
        if let data = defaults?.data(forKey: widgetDataKey),
           let decoded = try? JSONDecoder().decode([WidgetDepartureData].self, from: data) {
            items = decoded
        }
        if let d = defaults?.object(forKey: widgetLastUpdatedKey) as? Date {
            last = d
        }
        return (items, last)
    }

    private func saveCached(items: [WidgetDepartureData], lastUpdated: Date?) {
        let defaults = UserDefaults(suiteName: appGroupID)
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(items) {
            defaults?.set(data, forKey: widgetDataKey)
        }
        if let lastUpdated {
            defaults?.set(lastUpdated, forKey: widgetLastUpdatedKey)
        } else {
            defaults?.removeObject(forKey: widgetLastUpdatedKey)
        }
    }

    // MARK: - Fetch during timeline generation
    private func fetchFavoritesData(
        cached: [WidgetDepartureData]
    ) async -> (items: [WidgetDepartureData], isComplete: Bool)? {
        let routes = loadFavoritesFromDefaults()
        guard !routes.isEmpty else { return ([], true) }

        let selected = Array(routes.prefix(3))
        var groups: [FavoriteStationGroup] = []
        var groupIndexByDiva: [Int: Int] = [:]
        for favourite in selected {
            guard let diva = Int(favourite.diva) else { continue }
            if let index = groupIndexByDiva[diva] {
                groups[index].favourites.append(favourite)
            } else {
                groupIndexByDiva[diva] = groups.count
                groups.append(FavoriteStationGroup(diva: diva, favourites: [favourite]))
            }
        }

        var fresh: [WidgetDepartureData] = []
        for (index, group) in groups.enumerated() {
            if index > 0 {
                try? await Task.sleep(for: .milliseconds(500))
            }
            guard !Task.isCancelled else { return nil }
            do {
                let response = try await fetchMonitorData(diva: group.diva, includeArea: true)
                fresh.append(contentsOf: group.favourites.compactMap {
                    extractWidgetData(from: response, matching: $0)
                })
            } catch {
                continue
            }
        }

        guard !fresh.isEmpty else { return nil }
        let selectedKeys = selected.map {
            WidgetRouteKey(
                diva: $0.diva,
                lineName: $0.lineName,
                destination: $0.destination
            )
        }
        return (
            WidgetDataMerge.ordered(
                selected: selectedKeys,
                fresh: fresh,
                cached: cached
            ),
            fresh.count == selected.count
        )
    }

    private func extractWidgetData(from response: MonitorResponse, matching fav: FavoriteRoute) -> WidgetDepartureData? {
        let monitors = response.data.monitors
        guard !monitors.isEmpty else { return nil }
        guard let line = monitors.flatMap({ $0.lines }).first(where: { line in
            RouteMatching.matches(
                lineName: line.name, towards: line.towards,
                favoriteLine: fav.lineName, favoriteDestination: fav.destination
            )
        }) else { return nil }

        let minutes = line.departures.departure.map { $0.departureTime.countdown }
        let top = Array(minutes.prefix(3))
        let stopName = monitors.first?.locationStop?.properties.title ?? fav.diva
        return WidgetDepartureData(
            diva: fav.diva,
            lineName: fav.lineName,
            stopName: stopName,
            destination: fav.destination,
            departures: top,
            fetchedAt: .now
        )
    }
}

private struct WidgetLineBadge: View {
    let line: String
    var body: some View {
        Text(line)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(LineColors.color(for: line), in: RoundedRectangle(cornerRadius: 5))
    }
}

// MARK: - Widget UI

struct TrafficViennaWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: Provider.Entry

    var body: some View {
        Group {
            if entry.items.isEmpty {
                emptyState
            } else {
                switch family {
                case .systemSmall:
                    smallView
                case .systemMedium:
                    mediumView
                case .systemLarge:
                    largeView
                case .accessoryCircular:
                    accessoryCircularView
                case .accessoryRectangular:
                    accessoryRectangularView
                case .accessoryInline:
                    accessoryInlineView
                default:
                    mediumView
                }
            }
        }
    }

    // MARK: Empty

    @ViewBuilder
    private var emptyState: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "star")
                    .font(.title2)
                    .widgetAccentable()
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Label("Traffic Vienna", systemImage: "tram.fill")
                    .font(.headline)
                    .widgetAccentable()
                Text("Add a favourite line in the app.")
                    .font(.caption)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .accessoryInline:
            Label("Add a favourite departure", systemImage: "star")
        default:
            VStack(spacing: 8) {
                Image(systemName: "star")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("No favourites yet")
                    .font(.headline)
                Text("Tap the heart on a line in the app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: Small — first favourite, prominent

    private var smallView: some View {
        let item = entry.items[0]
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                WidgetLineBadge(line: item.lineName)
                Spacer(minLength: 0)
                refreshButton
            }
            Text(item.destination)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer(minLength: 0)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(item.departures.first.map(timeString) ?? "–")
                    .font(.system(size: 34, weight: .semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                if let first = item.departures.first, first > 0 {
                    Text("min").font(.caption).foregroundStyle(.secondary)
                }
            }
            if item.departures.count > 1 {
                let following = item.departures.dropFirst().prefix(2).map(String.init).joined(separator: ", ")
                Text("\(following) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
            updatedLabel
        }
    }

    // MARK: Medium — up to 3 favourites

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Departures").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Spacer()
                refreshButton
            }
            ForEach(entry.items.prefix(3).indices, id: \.self) { idx in
                row(entry.items[idx])
                if idx != min(2, entry.items.count - 1) {
                    Divider().opacity(0.25)
                }
            }
            Spacer(minLength: 0)
            updatedLabel
        }
    }

    // MARK: Large — a glanceable commute board

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Vienna departures")
                        .font(.title3.bold())
                    Text("Your next saved connections")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                refreshButton
            }

            ForEach(entry.items.prefix(3).indices, id: \.self) { index in
                largeRow(entry.items[index])
            }

            Spacer(minLength: 0)
            updatedLabel
        }
    }

    private func largeRow(_ item: WidgetDepartureData) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                WidgetLineBadge(line: item.lineName)
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.destination)
                        .font(.headline)
                        .lineLimit(1)
                    Text(item.stopName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }

            HStack(spacing: 8) {
                ForEach(Array(item.departures.prefix(3).enumerated()), id: \.offset) { index, minute in
                    Text(timeString(minute))
                        .font(index == 0 ? .title2.bold() : .headline)
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background(
                            index == 0
                                ? Color.accentColor.opacity(0.14)
                                : Color.primary.opacity(0.05),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                }
            }
        }
        .padding(12)
        .background(
            Color.primary.opacity(0.04),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    // MARK: Lock Screen

    private var accessoryCircularView: some View {
        let item = entry.items[0]
        return ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text(item.lineName)
                    .font(.caption.bold())
                    .widgetAccentable()
                Text(item.departures.first.map(timeString) ?? "–")
                    .font(.title2.bold())
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                if item.departures.first.map({ $0 > 0 }) == true {
                    Text("min")
                        .font(.system(size: 8, weight: .semibold))
                }
            }
        }
    }

    private var accessoryRectangularView: some View {
        let item = entry.items[0]
        return HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(item.lineName) → \(item.destination)")
                    .font(.headline)
                    .lineLimit(1)
                    .widgetAccentable()
                Text(item.stopName)
                    .font(.caption)
                    .lineLimit(1)
                if item.departures.count > 1 {
                    Text("\(item.departures.dropFirst().prefix(2).map(String.init).joined(separator: ", ")) min")
                        .font(.caption2)
                }
            }
            Spacer(minLength: 4)
            VStack(spacing: 0) {
                Text(item.departures.first.map(timeString) ?? "–")
                    .font(.title.bold())
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                if item.departures.first.map({ $0 > 0 }) == true {
                    Text("min").font(.caption2)
                }
            }
        }
    }

    private var accessoryInlineView: some View {
        let item = entry.items[0]
        return Label(
            "\(item.lineName) → \(item.destination): \(item.departures.first.map(timeString) ?? "–") min",
            systemImage: "tram.fill"
        )
    }

    private func row(_ item: WidgetDepartureData) -> some View {
        HStack(spacing: 8) {
            WidgetLineBadge(line: item.lineName)
            Text(item.destination)
                .font(.subheadline)
                .lineLimit(1)
            Spacer(minLength: 4)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(item.departures.first.map(timeString) ?? "–")
                    .font(.headline)
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                if let first = item.departures.first, first > 0 {
                    Text("min").font(.caption).foregroundStyle(.secondary)
                }
            }
            if item.departures.count > 1 {
                Text("\(item.departures[1])")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.tertiary)
                    .frame(width: 18, alignment: .trailing)
            }
        }
    }

    // MARK: Bits

    private var refreshButton: some View {
        Button(intent: RefreshFavoritesIntent()) {
            Image(systemName: "arrow.clockwise").font(.caption)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .accessibilityLabel("Refresh")
    }

    @ViewBuilder
    private var updatedLabel: some View {
        if let last = entry.lastUpdated {
            Text("Updated \(last, style: .relative)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private func timeString(_ minutes: Int) -> String {
        minutes <= 0 ? String(localized: "now") : "\(minutes)"
    }

}

// Widget setup
struct TrafficViennaWidget: Widget {
    let kind: String = "TrafficViennaWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            TrafficViennaWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Departures")
        .description("Live departures for your favourite lines.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}

// MARK: - Live Activity (Lock Screen + Dynamic Island)

private func clampedRange(to end: Date) -> ClosedRange<Date> {
    let now = Date.now
    return now ... max(end, now.addingTimeInterval(1))
}

struct DepartureLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DepartureActivityAttributes.self) { context in
            HStack(spacing: 12) {
                WidgetLineBadge(line: context.attributes.line)
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.destination).font(.headline).lineLimit(1)
                    Text(context.attributes.stopName).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(timerInterval: clampedRange(to: context.state.departureDate), countsDown: true)
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()
                        .multilineTextAlignment(.trailing)
                        .frame(width: 78)
                    Text("to departure").font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding()
            .activityBackgroundTint(.black)
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    WidgetLineBadge(line: context.attributes.line)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: clampedRange(to: context.state.departureDate), countsDown: true)
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                        .frame(width: 70)
                        .foregroundStyle(.green)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("→ \(context.attributes.destination)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                WidgetLineBadge(line: context.attributes.line)
            } compactTrailing: {
                Text(timerInterval: clampedRange(to: context.state.departureDate), countsDown: true)
                    .monospacedDigit()
                    .frame(width: 44)
                    .foregroundStyle(.green)
            } minimal: {
                Image(systemName: "tram.fill").foregroundStyle(.green)
            }
        }
    }
}

private let previewItems = [
    WidgetDepartureData(lineName: "U1", stopName: "", destination: "Leopoldau", departures: [2, 7, 12]),
    WidgetDepartureData(lineName: "O", stopName: "", destination: "Praterstern", departures: [3, 9, 14]),
    WidgetDepartureData(lineName: "59A", stopName: "", destination: "Kaisermühlen", departures: [0, 8, 16])
]

#Preview(as: .systemSmall) {
    TrafficViennaWidget()
} timeline: {
    SimpleEntry(date: .now, items: previewItems, lastUpdated: .now)
}

#Preview(as: .systemMedium) {
    TrafficViennaWidget()
} timeline: {
    SimpleEntry(date: .now, items: previewItems, lastUpdated: .now)
}

#Preview(as: .systemLarge) {
    TrafficViennaWidget()
} timeline: {
    SimpleEntry(date: .now, items: previewItems, lastUpdated: .now)
}

#Preview(as: .accessoryRectangular) {
    TrafficViennaWidget()
} timeline: {
    SimpleEntry(date: .now, items: previewItems, lastUpdated: .now)
}
