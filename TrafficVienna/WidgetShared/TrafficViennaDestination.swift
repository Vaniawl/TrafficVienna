import Foundation

nonisolated enum TrafficViennaDestination: String, CaseIterable, Codable, Hashable, Sendable {
    case nearby
    case search
    case favourites

    static let deepLinkScheme = "trafficvienna"

    init?(deepLinkURL url: URL) {
        guard url.scheme?.lowercased() == Self.deepLinkScheme,
              url.user == nil,
              url.password == nil,
              url.port == nil,
              url.query == nil,
              url.fragment == nil,
              url.path.isEmpty || url.path == "/",
              let host = url.host?.lowercased(),
              let destination = Self(rawValue: host)
        else {
            return nil
        }

        self = destination
    }

    var deepLinkURL: URL? {
        var components = URLComponents()
        components.scheme = Self.deepLinkScheme
        components.host = rawValue
        return components.url
    }
}
