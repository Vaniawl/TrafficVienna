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

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: .now,
            lineName: "U1",
            stopName: "Stephansplatz",
            destination: "Leopoldau",
            departures: [2, 7, 12]
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(
            date: .now,
            lineName: "U1",
            stopName: "Stephansplatz",
            destination: "Leopoldau",
            departures: [2, 7, 12]
        )
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = SimpleEntry(
            date: .now,
            lineName: "U1",
            stopName: "Stephansplatz",
            destination: "Leopoldau",
            departures: [2, 7, 12]
        )

        let timeline = Timeline(entries: [entry], policy: .never)
        return timeline
    }
}


struct TrafficViennaWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Лінія
            Text(entry.lineName)
                .font(.headline)
                .bold()

            // Зупинка
            Text(entry.stopName)
                .font(.subheadline)

            // Напрямок
            Text(entry.destination)
                .font(.subheadline)

            // Три наступні відправлення
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
