//
//  FavView.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 29.11.25.
//

import SwiftUI

struct FavView: View {
    @State private var favorites: [FavoriteRoute] = []
    
    var body: some View {
        VStack {
            NavigationStack {
                List(favorites, id: \.self) { fav in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(fav.lineName) to \(fav.destination)")
                                .font(.headline)
                            Text("Diva: \(fav.diva)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                    }
                    .padding(.vertical, 8)
                }
                .navigationTitle("Favourites")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear all favs") {
                            FavoritesManager.clear()
                            favorites = []
                        }
                    }
                }
            }
            .onAppear {
                favorites = FavoritesManager.all()
            }
        }
    }
}

#Preview {
    FavView()
}
