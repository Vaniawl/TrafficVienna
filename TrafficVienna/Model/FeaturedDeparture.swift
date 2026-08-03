import Foundation

struct FeaturedDeparture: Equatable, Identifiable {
    let route: FavoriteRoute
    let stopName: String
    let departure: DepartureInfo
    let state: FavoriteDepartureState
    let updatedAt: Date?

    init(
        route: FavoriteRoute,
        stopName: String,
        departure: DepartureInfo,
        state: FavoriteDepartureState,
        updatedAt: Date? = nil
    ) {
        self.route = route
        self.stopName = stopName
        self.departure = departure
        self.state = state
        self.updatedAt = updatedAt
    }

    var id: FavoriteRoute { route }
}
