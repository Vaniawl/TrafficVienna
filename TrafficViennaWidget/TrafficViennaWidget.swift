//
//  TrafficViennaWidget.swift
//  TrafficViennaWidget
//
//  Created by Ivan Dovhosheia on 23.11.25.
//

import WidgetKit
import SwiftUI
import AppIntents

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

        let entry = SimpleEntry(date: now, items: items.isEmpty ? demoItems() : items, lastUpdated: lastUpdated)
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

    private func demoItems() -> [WidgetDepartureData] {
        [
            WidgetDepartureData(lineName: "U1", stopName: "Stephansplatz", destination: "Leopoldau", departures: [2,7,12]),
            WidgetDepartureData(lineName: "O", stopName: "Praterstern", destination: "Migerka", departures: [3,9,14])
        ]
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

// Widget UI
struct TrafficViennaWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(entry.items.indices, id: \.self) { idx in
                let item = entry.items[idx]
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(item.lineName) → \(item.destination)")
                        .font(.headline)
                    Text(item.stopName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(item.departures.map { "\($0) min" }.joined(separator: ", "))
                        .font(.caption)
                }
                if idx != entry.items.indices.last {
                    Divider().opacity(0.2)
                }
            }

            Spacer(minLength: 0)

            HStack {
                if let last = entry.lastUpdated {
                    Text(relativeUpdatedString(since: last))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(intent: RefreshFavoritesIntent()) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Refresh")
            }
        }
        .padding(8)
    }

    private func relativeUpdatedString(since date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        let str = formatter.localizedString(for: date, relativeTo: .now)
        return "Updated \(str)"
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
    }
}



#Preview(as: .systemSmall) {
    TrafficViennaWidget()
} timeline: {
    SimpleEntry(date: .now, items: [
        WidgetDepartureData(lineName: "U1", stopName: "Stephansplatz", destination: "Leopoldau", departures: [2,7,12]),
        WidgetDepartureData(lineName: "O", stopName: "Praterstern", destination: "Migerka", departures: [3,9,14])
    ], lastUpdated: Date())
}
