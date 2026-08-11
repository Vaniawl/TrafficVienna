import Combine
import Foundation

extension TrafficViennaDestination {
    var appTab: AppTab {
        switch self {
        case .nearby:
            .nearby
        case .search:
            .search
        case .favourites:
            .favourites
        }
    }
}

protocol ShortcutDestinationStoring: AnyObject {
    func string(forKey defaultName: String) -> String?
    func set(_ value: Any?, forKey defaultName: String)
    func removeObject(forKey defaultName: String)
}

extension UserDefaults: ShortcutDestinationStoring {}

/// Persists navigation requests from integrations so they survive a cold app launch.
@MainActor
final class TrafficViennaShortcutRouter: ObservableObject {
    static let shared = TrafficViennaShortcutRouter()
    static let pendingDestinationKey = "pending_shortcut_destination"

    @Published private(set) var pendingDestination: TrafficViennaDestination?

    private let defaults: ShortcutDestinationStoring

    init(defaults: ShortcutDestinationStoring = UserDefaults.standard) {
        self.defaults = defaults
        pendingDestination = defaults.string(forKey: Self.pendingDestinationKey)
            .flatMap(TrafficViennaDestination.init(rawValue:))
    }

    func request(_ destination: TrafficViennaDestination) {
        defaults.set(destination.rawValue, forKey: Self.pendingDestinationKey)
        pendingDestination = destination
    }

    @discardableResult
    func consume() -> TrafficViennaDestination? {
        let destination = pendingDestination
        defaults.removeObject(forKey: Self.pendingDestinationKey)
        pendingDestination = nil
        return destination
    }

    @discardableResult
    func handle(deepLinkURL url: URL) -> Bool {
        guard let destination = TrafficViennaDestination(deepLinkURL: url) else {
            return false
        }
        request(destination)
        return true
    }
}
