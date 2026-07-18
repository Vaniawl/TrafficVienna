import Foundation
import Combine

@MainActor
final class AppRouter: ObservableObject {
    enum Destination: Equatable {
        case nearby
        case search
        case map
        case alerts
        case favourites
        case station(Int)
    }

    @Published private(set) var destination: Destination?

    func navigate(to destination: Destination) {
        self.destination = destination
    }

    func open(_ url: URL) {
        guard url.scheme == "trafficvienna" else { return }
        let components = [url.host].compactMap { $0 } + url.pathComponents.filter { $0 != "/" }
        guard let first = components.first else { return }
        switch first {
        case "nearby": destination = .nearby
        case "search": destination = .search
        case "map": destination = .map
        case "alerts": destination = .alerts
        case "favourites": destination = .favourites
        case "station":
            if components.count > 1, let id = Int(components[1]) { destination = .station(id) }
        default: break
        }
    }

    func consume() { destination = nil }
}
