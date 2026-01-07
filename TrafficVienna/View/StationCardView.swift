//
//  StationCardView.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 07.01.26.
//
import SwiftUI

struct StationCardView: View {
    let station: Station
    @StateObject private var vm: NearbyStationsViewModel

    init(station: Station) {
        self.station = station
        _vm = StateObject(wrappedValue: NearbyStationsViewModel(station: station))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(station.name)
                .font(.headline)

            if station.diva == nil {
                Text("No live-data for this stop")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if vm.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Loading…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if let error = vm.errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            } else if vm.lines.isEmpty {
                Text("No departures")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                // Show up to three lines with their next departures
                ForEach(Array(vm.lines.prefix(3).enumerated()), id: \.offset) { _, line in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(line.name)
                            .font(.headline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.gray.opacity(0.15)))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("→ \(line.towards)")
                                .font(.subheadline)
                            let minutes = line.departures.departure.map { $0.departureTime.countdown }
                            if !minutes.isEmpty {
                                Text(minutes.prefix(3).map { "\($0) хв" }.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .task { await vm.load() }
    }
}
#Preview {
    StationCardView(
        station: Station(id: 1, diva: 123456, name: "Karlsplatz", lat: 48.226242, lon: 16.391295)
    )
}


