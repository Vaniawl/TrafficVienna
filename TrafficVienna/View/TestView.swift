//
//  TestView.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 11.11.25.
//

import SwiftUI

struct TestView: View {
    @StateObject private var store = StationStore()
    @StateObject private var favoritesVM = FavoritesListViewModel()
    @State private var query = ""
    @State private var diva: Int? = nil
    
    var suggestions: [Station] {
        store.stationsSuggestion(matching: query)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            NavigationLink {
                FavView(vm: favoritesVM)
            } label: {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                Text("View favourites")

            }
            
            Text("Loaded stations: \(store.stations.count)")
            
            TextField("Enter the name stop...", text: $query)
                .textFieldStyle(.roundedBorder)
            
            if !suggestions.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(suggestions.prefix(10), id: \.id) { station in
                            NavigationLink {
                                TestView2(vm: StationDetailViewModel(station: station))
                            } label: {
                                HStack {
                                    Text(station.name)
                                    Spacer()
                                    
                                }
                            }
                        }
                    }
                }
            }

            Button("Find Diva") {
                diva = store.diva(forExact: query)
            }
            
            if let diva {
                Text("DIVA: \(diva)")
            } else {
                Text("Nothing to show")
            }
        }
        .padding()

    }
}

#Preview {
    TestView()
}
