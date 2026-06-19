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

// Local copy of favorites model stored in App Group
private struct FavoriteRoute: Codable, Hashable {
    let diva: String
    let lineName: String
    let destination: String
}

private let favoritesKey = "favorite_routes"

// DTOs for decoding monitor response inside the widget target
private struct MonitorResponse: Decodable { let data: DataBlock }
private struct DataBlock: Decodable { let monitors: [Monitor] }
private struct Monitor: Decodable { let lines: [Lines] }
private struct Lines: Decodable { let name: String; let towards: String; let departures: Departures }
private struct Departures: Decodable { let departure: [Departure] }
private struct Departure: Decodable { let departureTime: DepartureTime }
private struct DepartureTime: Decodable { let countdown: Int }

// Local network fetcher for widget
private func fetchMonitorData(diva: Int, includeArea: Bool) async throws -> MonitorResponse {
    var urlString = "https://www.wienerlinien.at/ogd_realtime/monitor?diva=\(diva)"
    if includeArea { urlString += "&aArea=1" }
    guard let url = URL(string: urlString) else { throw URLError(.badURL) }
    let (data, response) = try await URLSession.shared.data(from: url)
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
    return Array(decoded)
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
            lastUpdated: Date()
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let (items, lastUpdated) = loadCached()
        if items.isEmpty {
            return placeholder(in: context)
        } else {
            return SimpleEntry(date: .now, items: items, lastUpdated: lastUpdated)
        }
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let defaults = UserDefaults(suiteName: appGroupID)
        let now = Date()
        let lastAttempt = defaults?.object(forKey: widgetLastFetchAttemptKey) as? Date ?? .distantPast
        let canFetch = now.timeIntervalSince(lastAttempt) >= 60

        var (items, lastUpdated) = loadCached()

        if canFetch {
            defaults?.set(now, forKey: widgetLastFetchAttemptKey)
            if let fresh = await fetchFavoritesData() {
                items = fresh
                lastUpdated = now
                saveCached(items: items, lastUpdated: now)
            }
        }

        let entry = SimpleEntry(date: now, items: items, lastUpdated: lastUpdated)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: now)!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
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

    private func saveCached(items: [WidgetDepartureData], lastUpdated: Date) {
        let defaults = UserDefaults(suiteName: appGroupID)
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(items) {
            defaults?.set(data, forKey: widgetDataKey)
        }
        defaults?.set(lastUpdated, forKey: widgetLastUpdatedKey)
    }

    // MARK: - Fetch during timeline generation
    private func fetchFavoritesData() async -> [WidgetDepartureData]? {
        let routes = loadFavoritesFromDefaults()
        guard !routes.isEmpty else { return nil }

        var results: [WidgetDepartureData] = []
        for fav in routes.prefix(3) {
            guard let diva = Int(fav.diva) else { continue }
            do {
                let response = try await fetchMonitorData(diva: diva, includeArea: true)
                if let item = extractWidgetData(from: response, matching: fav) {
                    results.append(item)
                }
            } catch {
                continue
            }
        }
        return results
    }

    private func extractWidgetData(from response: MonitorResponse, matching fav: FavoriteRoute) -> WidgetDepartureData? {
        func normalize(_ s: String) -> String {
            s.replacingOccurrences(of: " U", with: "")
             .replacingOccurrences(of: " S", with: "")
             .trimmingCharacters(in: .whitespacesAndNewlines)
             .lowercased()
        }
        let monitors = response.data.monitors
        guard !monitors.isEmpty else { return nil }
        guard let line = monitors.flatMap({ $0.lines }).first(where: { line in
            line.name == fav.lineName && normalize(line.towards) == normalize(fav.destination)
        }) else { return nil }

        let minutes = line.departures.departure.map { $0.departureTime.countdown }
        let top = Array(minutes.prefix(3))
        return WidgetDepartureData(lineName: fav.lineName, stopName: fav.diva, destination: fav.destination, departures: top)
    }
}

// MARK: - Line styling (self-contained for the widget target)

private extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}

private func widgetLineColor(_ line: String) -> Color {
    let name = line.uppercased().trimmingCharacters(in: .whitespaces)
    switch name {
    case "U1": return Color(hex: 0xE20917)
    case "U2": return Color(hex: 0xA862A4)
    case "U3": return Color(hex: 0xEF7C00)
    case "U4": return Color(hex: 0x00963F)
    case "U6": return Color(hex: 0x9B6A30)
    default: break
    }
    if name.hasPrefix("U") { return Color(hex: 0x1C6BA0) }
    if name.hasPrefix("S") { return Color(hex: 0x004A99) }
    if name.hasPrefix("N") { return Color(hex: 0x1A2A6C) }
    if name.range(of: "^[0-9]+[AB]$", options: .regularExpression) != nil { return Color(hex: 0x004A99) }
    return Color(hex: 0xE2002A)
}

private struct WidgetLineBadge: View {
    let line: String
    var body: some View {
        Text(line)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(widgetLineColor(line), in: RoundedRectangle(cornerRadius: 5))
    }
}

// MARK: - Widget UI

struct TrafficViennaWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: Provider.Entry

    var body: some View {
        if entry.items.isEmpty {
            emptyState
        } else if family == .systemSmall {
            smallView
        } else {
            mediumView
        }
    }

    // MARK: Empty

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "star")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("No favourites yet")
                .font(.subheadline.weight(.medium))
            Text("Tap the heart on a line in the app.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                if let first = item.departures.first, first > 0 {
                    Text("min").font(.caption).foregroundStyle(.secondary)
                }
            }
            if item.departures.count > 1 {
                Text("then " + item.departures.dropFirst().prefix(2).map { "\($0)" }.joined(separator: ", ") + " min")
                    .font(.caption2)
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
                if let first = item.departures.first, first > 0 {
                    Text("min").font(.caption2).foregroundStyle(.secondary)
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
            Image(systemName: "arrow.clockwise").font(.caption2)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .accessibilityLabel("Refresh")
    }

    @ViewBuilder
    private var updatedLabel: some View {
        if let last = entry.lastUpdated {
            Text(relativeUpdatedString(since: last))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private func timeString(_ minutes: Int) -> String {
        minutes <= 0 ? "now" : "\(minutes)"
    }

    private func relativeUpdatedString(since date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return "Updated \(formatter.localizedString(for: date, relativeTo: .now))"
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
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Live Activity (Lock Screen + Dynamic Island)

private func clampedRange(to end: Date) -> ClosedRange<Date> {
    let now = Date()
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
                    Text("to departure").font(.caption2).foregroundStyle(.secondary)
                }
            }
            .padding()
            .activityBackgroundTint(Color(hex: 0x15171C))
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
    SimpleEntry(date: .now, items: previewItems, lastUpdated: Date())
}

#Preview(as: .systemMedium) {
    TrafficViennaWidget()
} timeline: {
    SimpleEntry(date: .now, items: previewItems, lastUpdated: Date())
}
