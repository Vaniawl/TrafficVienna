import Foundation

nonisolated struct FavoriteRoute: Codable, Hashable, Comparable, Sendable {
    let diva: String
    let lineName: String
    let destination: String

    var stableID: String {
        [diva, lineName, destination]
            .map { Data($0.utf8).base64EncodedString() }
            .joined(separator: ".")
    }

    static func < (lhs: FavoriteRoute, rhs: FavoriteRoute) -> Bool {
        [lhs.lineName, lhs.destination, lhs.diva]
            .lexicographicallyPrecedes([rhs.lineName, rhs.destination, rhs.diva])
    }
}
