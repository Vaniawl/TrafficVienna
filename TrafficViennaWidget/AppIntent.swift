//
//  AppIntent.swift
//  TrafficViennaWidget
//
//  Created by Ivan Dovhosheia on 23.11.25.
//

import WidgetKit
import AppIntents

private let appGroupID = "group.wellbe.TrafficVienna"
private let favoritesKey = "favorite_routes"

struct FavoriteRouteEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Saved route",
        numericFormat: "\(placeholder: .int) saved routes"
    )
    static var defaultQuery = FavoriteRouteEntityQuery()

    let id: String
    let diva: String
    let lineName: String
    let destination: String

    init(route: FavoriteRoute) {
        id = route.stableID
        diva = route.diva
        lineName = route.lineName
        destination = route.destination
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(lineName) → \(destination)",
            subtitle: "Saved departure"
        )
    }

    var route: FavoriteRoute {
        FavoriteRoute(
            diva: diva,
            lineName: lineName,
            destination: destination
        )
    }
}

struct FavoriteRouteEntityQuery: EntityQuery {
    func entities(
        for identifiers: [FavoriteRouteEntity.ID]
    ) async throws -> [FavoriteRouteEntity] {
        WidgetRouteEntityResolution.routes(
            for: identifiers,
            availableRoutes: savedRoutes()
        )
            .map(FavoriteRouteEntity.init)
    }

    func suggestedEntities() async throws -> [FavoriteRouteEntity] {
        savedRoutes().map(FavoriteRouteEntity.init)
    }

    private func savedRoutes() -> [FavoriteRoute] {
        let defaults = UserDefaults(suiteName: appGroupID)
        guard let data = defaults?.data(forKey: favoritesKey),
              let routes = try? JSONDecoder().decode(Set<FavoriteRoute>.self, from: data)
        else {
            return []
        }
        return routes.sorted()
    }
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Departures" }
    static var description: IntentDescription { "Live departures for your favourite lines." }

    @Parameter(
        title: "Routes",
        description: "Choose which saved routes appear in this widget.",
        default: [],
        size: [
            .systemSmall: IntentCollectionSize(min: 0, max: 1),
            .systemMedium: IntentCollectionSize(min: 0, max: 3),
            .systemLarge: IntentCollectionSize(min: 0, max: 3),
            .accessoryCircular: IntentCollectionSize(min: 0, max: 1),
            .accessoryRectangular: IntentCollectionSize(min: 0, max: 1),
            .accessoryInline: IntentCollectionSize(min: 0, max: 1),
        ]
    )
    var routes: [FavoriteRouteEntity]

    static var parameterSummary: some ParameterSummary {
        Summary("Departures for \(\.$routes)")
    }
}

struct RefreshFavoritesIntent: AppIntent {
    static var title: LocalizedStringResource { "Refresh Favorites" }
    static var description = IntentDescription("Request the widget to refresh its data.")
    
    func perform() async throws -> some IntentResult {
        // Mark the time a refresh was requested (for debugging/throttling if needed)
        let defaults = UserDefaults(suiteName: "group.wellbe.TrafficVienna")
        defaults?.set(Date.now, forKey: "widget_refresh_requested_at")

        // Ask the system to reload our widget timelines
        WidgetCenter.shared.reloadTimelines(ofKind: "TrafficViennaWidget")
        return .result()
    }
}
