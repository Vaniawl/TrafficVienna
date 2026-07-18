struct FavoriteWithDeparture: Identifiable {
    let route: FavoriteRoute
    let stopName: String
    let departures: [DepartureInfo]
    let state: FavoriteDepartureState

    var id: FavoriteRoute { route }
}
