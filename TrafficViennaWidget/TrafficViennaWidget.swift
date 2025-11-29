//
//  TrafficViennaWidget.swift
//  TrafficViennaWidget
//
//  Created by Ivan Dovhosheia on 23.11.25.
//

import WidgetKit
import SwiftUI

struct SimpleEntry: TimelineEntry {
    let date: Date
    let lineName: String
    let stopName: String
    let destination: String
    let departures: [Int]
}
// shared app group
private let appGroupID = "group.wellbe.TrafficVienna"

// provides widget data
struct Provider: AppIntentTimelineProvider {
    // Widget preview
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: .now,
            lineName: "U1",
            stopName: "Stephansplatz",
            destination: "Leopoldau",
            departures: [2, 7, 12]
        )
    }
    // Quick preview
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(
            date: .now,
            lineName: "U1",
            stopName: "Stephansplatz",
            destination: "Leopoldau",
            departures: [2, 7, 12]
        )
    }
    // Load real data or fallback
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let defaults = UserDefaults(suiteName: appGroupID)

        let entry: SimpleEntry

        if
            let data = defaults?.data(forKey: "widget_departure"),
            let decoded = try? JSONDecoder().decode(WidgetDepartureData.self, from: data)
        {
            entry = SimpleEntry(
                date: .now,
                lineName: decoded.lineName,
                stopName: decoded.stopName,
                destination: decoded.destination,
                departures: decoded.departures
            )
        } else {
            entry = SimpleEntry(
                date: .now,
                lineName: "U1",
                stopName: "Stephansplatz",
                destination: "Leopoldau",
                departures: [2, 7, 12]
            )
        }

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        return timeline
    }
}

// Widget UI
struct TrafficViennaWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.lineName)
                .font(.headline)
                .bold()

            Text(entry.stopName)
                .font(.subheadline)

            Text(entry.destination)
                .font(.subheadline)

            VStack(alignment: .leading, spacing: 2) {
                ForEach(entry.departures.indices, id: \.self) { index in
                    let minutes = entry.departures[index]
                    Text("через \(minutes) хв")
                        .font(.caption)
                }
            }
        }
        .padding(8)
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
    SimpleEntry(
        date: .now,
        lineName: "U1",
        stopName: "Stephansplatz",
        destination: "Leopoldau",
        departures: [2, 7, 12]
    )
}


