import AppIntents
import Combine
import Foundation

nonisolated extension TrafficViennaDestination: AppEnum {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Destination"
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .nearby: "Nearby departures",
        .search: "Search stations",
        .favourites: "Favourite stops",
    ]
}

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

/// Persists intent-driven navigation so it also survives a cold app launch.
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

struct OpenTrafficViennaDestinationIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Traffic Vienna"
    static let description = IntentDescription(
        "Open Traffic Vienna at the part you need."
    )
    static var supportedModes: IntentModes { .foreground(.immediate) }

    @Parameter(title: "Destination")
    var target: TrafficViennaDestination

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$target) in Traffic Vienna")
    }

    init() {}

    init(target: TrafficViennaDestination) {
        self.target = target
    }

    func perform() async throws -> some IntentResult {
        await TrafficViennaShortcutRouter.shared.request(target)
        return .result()
    }
}

struct TrafficViennaAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenTrafficViennaDestinationIntent(target: .nearby),
            phrases: [
                "Show nearby departures in \(.applicationName)",
                "Open departures in \(.applicationName)",
            ],
            shortTitle: "Nearby departures",
            systemImageName: "location.fill"
        )

        AppShortcut(
            intent: OpenTrafficViennaDestinationIntent(target: .search),
            phrases: [
                "Search stations in \(.applicationName)",
                "Find a Vienna stop in \(.applicationName)",
            ],
            shortTitle: "Search stations",
            systemImageName: "magnifyingglass"
        )

        AppShortcut(
            intent: OpenTrafficViennaDestinationIntent(target: .favourites),
            phrases: [
                "Show my favourite stops in \(.applicationName)",
                "Open my saved stops in \(.applicationName)",
            ],
            shortTitle: "Favourite stops",
            systemImageName: "star.fill"
        )
    }

    static var shortcutTileColor: ShortcutTileColor { .navy }
}
