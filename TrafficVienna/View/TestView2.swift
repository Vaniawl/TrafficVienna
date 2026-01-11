//
//  TestView2.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 13.11.25.
//

import SwiftUI

struct TestView2: View {
    @StateObject private var vm: StationDetailViewModel
    
    init(station: Station) {
        _vm = StateObject(wrappedValue: StationDetailViewModel(station: station))
    }
   
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            //Name of station
            Text(vm.station.name)
                .font(.title)
                    
            if vm.isLoading {
                ProgressView("Loading...")
            } else if let error = vm.errorMessage {
                Text(error)
            } else if let monitor = vm.monitor {
                List {
                    ForEach(Array(monitor.data.monitors.enumerated()), id: \.offset) { monitorIndex, monitorItem in
                        let stopName = monitorItem.locationStop.properties.title
                        
                        Section(stopName) {
                            ForEach(monitorItem.lines.indices, id: \.self) { lineIndex in
                                let line = monitorItem.lines[lineIndex]
                                
                                NavigationLink {
                                    TestView3(line: line)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 16) {
                                            Text("\(line.name) -> \(line.towards)")
                                            
                                            Text("Departures: \(line.departures.departure.count)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if let divaInt = vm.station.diva {
                                            let diva = String(divaInt)
                                            let isFav = vm.isFavorite(line: line)
                                            Button {
                                                vm.toggleFavorite(line: line)
                                                print("button tapped")
                                            } label: {
                                                Image(systemName: isFav ? "heart.fill" : "heart")
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding()
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            } else {
                Text("No data yet")
                
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Station details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if vm.monitor == nil {
                await vm.load()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await vm.load()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
}

#Preview {
    let station = Station(
        id: 1,
        diva: 60201468,
        name: "Bruno-Marek-Allee",
        lat: 48.123,
        lon: 16.456
    )
    let vm = StationDetailViewModel(station: station)
    
    NavigationStack {
        TestView2(station: station)
    }
}
