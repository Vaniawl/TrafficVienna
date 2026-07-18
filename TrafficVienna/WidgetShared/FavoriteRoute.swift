import Foundation

nonisolated struct FavoriteRoute: Codable, Hashable, Comparable {
    let diva: String
    let lineName: String
    let destination: String

    static func < (lhs: FavoriteRoute, rhs: FavoriteRoute) -> Bool {
        [lhs.lineName, lhs.destination, lhs.diva]
            .lexicographicallyPrecedes([rhs.lineName, rhs.destination, rhs.diva])
    }
}
