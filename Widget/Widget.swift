//
//  Widget.swift
//  Widget
//
//  Created by Ivan Dovhosheia on 19.11.25.
//

import WidgetKit
import SwiftUI

struct DepartureEntry: TimelineEntry {
    let date: Date
    let lineName: String
    let towards: String
    let countdown: Int
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> DepartureEntry {
        DepartureEntry(date: .now, lineName: "U1", towards: "Leopoldau", countdown: 3)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DepartureEntry) -> Void) {
        let entry = DepartureEntry(date: .now, lineName: "U1", towards: "Leopoldau", countdown: 3)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DepartureEntry>) -> Void) {
        let entry = DepartureEntry(date: .now, lineName: "U1", towards: "Leopoldau", countdown: 3)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)

    }
}


struct TrafficViennaWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            Color.black
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.lineName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.orange)

                Text(entry.towards)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                Text("через \(entry.countdown) хв")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(8)
        }
    }
}

@main
struct TrafficViennaWidget: Widget {
    let kind: String = "TrafficViennaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TrafficViennaWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Traffic Vienna")
        .description("Показує наступний рейс (моки).")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    TrafficViennaWidget()
} timeline: {
    DepartureEntry(date: .now,
                   lineName: "U1",
                   towards: "Leopoldau",
                   countdown: 3)
}
