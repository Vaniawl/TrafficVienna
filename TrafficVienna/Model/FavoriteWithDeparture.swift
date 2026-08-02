import Foundation

struct FavoriteWithDeparture: Identifiable {
    let route: FavoriteRoute
    let stopName: String
    let departures: [DepartureInfo]
    let state: FavoriteDepartureState
    let updatedAt: Date?

    var id: FavoriteRoute { route }
}
