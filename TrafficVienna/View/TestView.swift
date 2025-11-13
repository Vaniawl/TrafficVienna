//
//  TestView.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 11.11.25.
//

import SwiftUI

struct TestView: View {
    @StateObject private var store = StationStore()
    @State private var query = ""
    @State private var diva: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Loaded stations: \(store.stations.count)")
            
            TextField("Enter the name stop...", text: $query)
                .textFieldStyle(.roundedBorder)
            
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
        .onAppear {
            print("🟡 TestView appeared, stations: \(store.stations.count)")
        }
    }
}

#Preview {
    TestView()
}
