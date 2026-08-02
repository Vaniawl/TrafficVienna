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
        let routes = selectedRoutes(
            for: configuration,
            family: context.family
        )
        let (cached, lastUpdated) = loadCached()
        let items = selectedItems(routes: routes, cached: cached)

        switch WidgetSnapshotPolicy.content(
            hasItems: !items.isEmpty,
            isPreview: context.isPreview
        ) {
        case .placeholder:
            return placeholder(in: context)
        case .empty:
            return SimpleEntry(
                date: .now,
                items: [],
                lastUpdated: nil
            )
        case .items:
            let now = Date.now
            return SimpleEntry(
                date: now,
                items: WidgetCountdownProjection.items(
                    items,
                    fallbackUpdatedAt: lastUpdated,
                    at: now
                ),
                lastUpdated: displayedUpdatedAt(
                    items: items,
                    fallback: lastUpdated
                )
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

        let routes = selectedRoutes(
            for: configuration,
            family: context.family
        )
        var (cached, lastUpdated) = loadCached()

        if canFetch {
            defaults?.set(now, forKey: widgetLastFetchAttemptKey)
            if let refresh = await fetchFavoritesData(
                routes: routes,
                cached: cached
            ) {
                cached = mergeCache(existing: cached, refreshed: refresh.items)
                if refresh.isComplete {
                    lastUpdated = now
                }
                saveCached(items: cached, lastUpdated: lastUpdated)
            }
        }

        let items = selectedItems(routes: routes, cached: cached)
        let displayDate = displayedUpdatedAt(
            items: items,
            fallback: lastUpdated
        )
        let futureDate = now.addingTimeInterval(5 * 60)
        let entryDates = WidgetTimelineSchedule.entryDates(
            now: now,
            refreshDate: futureDate,
            items: items,
            fallbackUpdatedAt: lastUpdated
        )
        let entries = entryDates.map { entryDate in
            SimpleEntry(
                date: entryDate,
                items: WidgetCountdownProjection.items(
                    items,
                    fallbackUpdatedAt: lastUpdated,
                    at: entryDate
                ),
                lastUpdated: displayDate
            )
        }
        return Timeline(
            entries: entries,
            policy: .after(futureDate)
        )
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

    private func selectedRoutes(
        for configuration: ConfigurationAppIntent,
        family: WidgetFamily
    ) -> [FavoriteRoute] {
        let configured = configuration.routes.map(\.route)
        let routes = configured.isEmpty ? loadFavoritesFromDefaults() : configured
        return Array(routes.prefix(routeLimit(for: family)))
    }

    private func routeLimit(for family: WidgetFamily) -> Int {
        switch family {
        case .systemMedium, .systemLarge:
            3
        default:
            1
        }
    }

    private func selectedItems(
        routes: [FavoriteRoute],
        cached: [WidgetDepartureData]
    ) -> [WidgetDepartureData] {
        WidgetDataMerge.ordered(
            selected: routes.map {
                WidgetRouteKey(
                    diva: $0.diva,
                    lineName: $0.lineName,
                    destination: $0.destination
                )
            },
            fresh: [],
            cached: cached
        )
    }

    private func mergeCache(
        existing: [WidgetDepartureData],
        refreshed: [WidgetDepartureData]
    ) -> [WidgetDepartureData] {
        let refreshedKeys = Set(
            refreshed.map {
                WidgetRouteKey(
                    diva: $0.diva,
                    lineName: $0.lineName,
                    destination: $0.destination
                )
            }
        )
        return existing.filter {
            !refreshedKeys.contains(
                WidgetRouteKey(
                    diva: $0.diva,
                    lineName: $0.lineName,
                    destination: $0.destination
                )
            )
        } + refreshed
    }

    private func displayedUpdatedAt(
        items: [WidgetDepartureData],
        fallback: Date?
    ) -> Date? {
        let rowDates = items.compactMap(\.fetchedAt)
        guard rowDates.count == items.count else {
            return fallback
        }
        return rowDates.min()
    }

    // MARK: - Fetch during timeline generation
    private func fetchFavoritesData(
        routes: [FavoriteRoute],
        cached: [WidgetDepartureData]
    ) async -> (items: [WidgetDepartureData], isComplete: Bool)? {
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

private struct WidgetCountdownText: View {
    let minutes: Int?
    let referenceDate: Date

    var body: some View {
        if let minutes {
            if minutes <= 0 {
                Text("now")
            } else {
                Text(
                    timerInterval: referenceDate ... referenceDate.addingTimeInterval(
                        TimeInterval(minutes * 60)
                    ),
                    countsDown: true,
                    showsHours: false
                )
            }
        } else {
            Text("–")
        }
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

            WidgetCountdownText(
                minutes: item.departures.first,
                referenceDate: entry.date
            )
            .font(.system(size: 30, weight: .semibold))
            .monospacedDigit()
            .minimumScaleFactor(0.75)
            .contentTransition(.numericText(countsDown: true))

            if item.departures.count > 1 {
                HStack(spacing: 6) {
                    ForEach(
                        Array(item.departures.dropFirst().prefix(2).enumerated()),
                        id: \.offset
                    ) { _, minutes in
                        WidgetCountdownText(
                            minutes: minutes,
                            referenceDate: entry.date
                        )
                    }
                }
                .font(.caption.monospacedDigit())
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
            if entry.items.count == 1, let item = entry.items.first {
                mediumHero(item)
            } else {
                ForEach(entry.items.prefix(3).indices, id: \.self) { idx in
                    row(entry.items[idx])
                    if idx != min(2, entry.items.count - 1) {
                        Divider().opacity(0.25)
                    }
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

            if entry.items.count == 1, let item = entry.items.first {
                largeHero(item)
                    .frame(maxHeight: .infinity)
            } else {
                ForEach(entry.items.prefix(3).indices, id: \.self) { index in
                    largeRow(entry.items[index])
                }
                Spacer(minLength: 0)
            }

            updatedLabel
        }
    }

    private func mediumHero(_ item: WidgetDepartureData) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                WidgetLineBadge(line: item.lineName)
                Text(item.destination)
                    .font(.headline)
                    .lineLimit(1)
                Text(item.stopName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            WidgetCountdownText(
                minutes: item.departures.first,
                referenceDate: entry.date
            )
            .font(.title2.bold())
            .monospacedDigit()
            .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 4)
    }

    private func largeHero(_ item: WidgetDepartureData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                WidgetLineBadge(line: item.lineName)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.destination)
                        .font(.title3.bold())
                        .lineLimit(1)
                    Text(item.stopName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Next departure")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                WidgetCountdownText(
                    minutes: item.departures.first,
                    referenceDate: entry.date
                )
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.7)
            }

            if item.departures.count > 1 {
                HStack(spacing: 10) {
                    ForEach(
                        Array(item.departures.dropFirst().prefix(2).enumerated()),
                        id: \.offset
                    ) { _, minutes in
                        WidgetCountdownText(
                            minutes: minutes,
                            referenceDate: entry.date
                        )
                        .font(.headline.monospacedDigit())
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .background(
                            Color.primary.opacity(0.06),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(16)
        .background(
            Color.primary.opacity(0.04),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
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
                    WidgetCountdownText(
                        minutes: minute,
                        referenceDate: entry.date
                    )
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
                WidgetCountdownText(
                    minutes: item.departures.first,
                    referenceDate: entry.date
                )
                    .font(.title2.bold())
                    .monospacedDigit()
                    .minimumScaleFactor(0.65)
                    .contentTransition(.numericText(countsDown: true))
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
                    HStack(spacing: 5) {
                        ForEach(
                            Array(item.departures.dropFirst().prefix(2).enumerated()),
                            id: \.offset
                        ) { _, minutes in
                            WidgetCountdownText(
                                minutes: minutes,
                                referenceDate: entry.date
                            )
                        }
                    }
                    .font(.caption2.monospacedDigit())
                }
            }
            Spacer(minLength: 4)
            WidgetCountdownText(
                minutes: item.departures.first,
                referenceDate: entry.date
            )
            .font(.title.bold())
            .monospacedDigit()
            .minimumScaleFactor(0.65)
            .contentTransition(.numericText(countsDown: true))
        }
    }

    private var accessoryInlineView: some View {
        let item = entry.items[0]
        return Label {
            HStack(spacing: 4) {
                Text("\(item.lineName) → \(item.destination):")
                WidgetCountdownText(
                    minutes: item.departures.first,
                    referenceDate: entry.date
                )
            }
        } icon: {
            Image(systemName: "tram.fill")
        }
    }

    private func row(_ item: WidgetDepartureData) -> some View {
        HStack(spacing: 8) {
            WidgetLineBadge(line: item.lineName)
            Text(item.destination)
                .font(.subheadline)
                .lineLimit(1)
            Spacer(minLength: 4)
            WidgetCountdownText(
                minutes: item.departures.first,
                referenceDate: entry.date
            )
            .font(.headline)
            .monospacedDigit()
            .minimumScaleFactor(0.75)
            .contentTransition(.numericText(countsDown: true))
            if item.departures.count > 1 {
                WidgetCountdownText(
                    minutes: item.departures[1],
                    referenceDate: entry.date
                )
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.tertiary)
                    .frame(width: 44, alignment: .trailing)
            }
        }
    }

    // MARK: Bits

    private var refreshButton: some View {
        Button(intent: RefreshFavoritesIntent()) {
            Image(systemName: "arrow.clockwise").font(.caption)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary.opacity(0.65))
        .accessibilityLabel("Refresh")
    }

    @ViewBuilder
    private var updatedLabel: some View {
        if let last = entry.lastUpdated {
            let elapsedMinutes = WidgetFreshness.elapsedWholeMinutes(
                since: last,
                at: entry.date
            )
            if elapsedMinutes == 0 {
                Text("Updated just now")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } else {
                Text("Updated \(last, style: .relative)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }

}

// Widget setup
struct TrafficViennaWidget: Widget {
    let kind: String = "TrafficViennaWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            TrafficViennaWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(TrafficViennaDestination.favourites.deepLinkURL)
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

#Preview(as: .accessoryCircular) {
    TrafficViennaWidget()
} timeline: {
    SimpleEntry(date: .now, items: previewItems, lastUpdated: .now)
}

#Preview(as: .accessoryInline) {
    TrafficViennaWidget()
} timeline: {
    SimpleEntry(date: .now, items: previewItems, lastUpdated: .now)
}
