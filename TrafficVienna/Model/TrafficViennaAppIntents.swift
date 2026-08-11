import AppIntents

nonisolated extension TrafficViennaDestination: AppEnum {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Destination"
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .nearby: "Nearby departures",
        .search: "Search stations",
        .favourites: "Favourite stops",
    ]
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
