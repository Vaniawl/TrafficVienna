import AppIntents
import Combine
import Foundation

enum TrafficViennaShortcutDestination: String, AppEnum {
    case nearby
    case search
    case favourites

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Destination"
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .nearby: "Nearby departures",
        .search: "Search stations",
        .favourites: "Favourite stops",
    ]

    var appDestination: AppRouter.Destination {
        switch self {
        case .nearby: .nearby
        case .search: .search
        case .favourites: .favourites
        }
    }
}

/// A small persisted handoff between an App Intent and the app's existing router.
///
/// Persisting the request makes cold launches reliable, while the published value
/// covers intents that run while the app is already active.
@MainActor
final class TrafficViennaShortcutRouter: ObservableObject {
    static let shared = TrafficViennaShortcutRouter()
    static let pendingDestinationKey = "pending_shortcut_destination"

    @Published private(set) var pendingDestination: TrafficViennaShortcutDestination?

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        pendingDestination = defaults.string(forKey: Self.pendingDestinationKey)
            .flatMap(TrafficViennaShortcutDestination.init(rawValue:))
    }

    func request(_ destination: TrafficViennaShortcutDestination) {
        defaults.set(destination.rawValue, forKey: Self.pendingDestinationKey)
        pendingDestination = destination
    }

    @discardableResult
    func consume() -> TrafficViennaShortcutDestination? {
        let destination = pendingDestination
        defaults.removeObject(forKey: Self.pendingDestinationKey)
        pendingDestination = nil
        return destination
    }
}

struct OpenTrafficViennaDestinationIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Traffic Vienna"
    static let description = IntentDescription(
        "Open Traffic Vienna at the part you need."
    )
    static var supportedModes: IntentModes { .foreground(.immediate) }

    @Parameter(title: "Destination")
    var target: TrafficViennaShortcutDestination

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$target) in Traffic Vienna")
    }

    init() {}

    init(target: TrafficViennaShortcutDestination) {
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
