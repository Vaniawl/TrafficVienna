//
//  FavView.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 29.11.25.
//

import SwiftUI

struct FavView: View {
    @StateObject private var vm = FavoritesListViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if vm.items.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "heart")
                            .font(.largeTitle)
                        
                        Text("No favourites yet")
                            .font(.headline)
                        
                        Text("Add routes with the heart button on a stop.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List(vm.items) { item in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(item.route.lineName) -> \(item.route.destination)")
                                    .font(.headline)
                                if item.departures.isEmpty {
                                    Text("No departures yet")
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text(
                                        item.departures.map { dep in
                                            let tag = dep.isRealtime ? "real" : "planned"
                                            return "\(dep.countdown) min (\(tag))"
                                        }
                                        .joined(separator: ", ")
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)

                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Favourites")
        }
        .onAppear {
            vm.load()
        }
    }
}

#Preview {
    FavView()
}
