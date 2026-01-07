//
//  AppIntent.swift
//  TrafficViennaWidget
//
//  Created by Ivan Dovhosheia on 23.11.25.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "This is an example widget." }

    // An example configurable parameter.
    @Parameter(title: "Favorite Emoji", default: "😃")
    var favoriteEmoji: String
}

struct RefreshFavoritesIntent: AppIntent {
    static var title: LocalizedStringResource { "Refresh Favorites" }
    static var description = IntentDescription("Request the widget to refresh its data.")
    
    func perform() async throws -> some IntentResult {
        // Mark the time a refresh was requested (for debugging/throttling if needed)
        let defaults = UserDefaults(suiteName: "group.wellbe.TrafficVienna")
        defaults?.set(Date(), forKey: "widget_refresh_requested_at")

        // Ask the system to reload our widget timelines
        WidgetCenter.shared.reloadTimelines(ofKind: "TrafficViennaWidget")
        return .result()
    }
}

