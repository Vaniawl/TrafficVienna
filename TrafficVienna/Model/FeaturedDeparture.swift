struct FeaturedDeparture: Equatable, Identifiable {
    let route: FavoriteRoute
    let stopName: String
    let departure: DepartureInfo
    let state: FavoriteDepartureState

    var id: FavoriteRoute { route }
}
