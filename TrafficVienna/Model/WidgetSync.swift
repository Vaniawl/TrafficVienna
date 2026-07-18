//
//  WidgetSync.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 25.11.25.
//

import Foundation
import WidgetKit
import OSLog

private let log = Logger(subsystem: "at.wellbe.TrafficVienna", category: "widget-sync")

protocol WidgetSyncing: Sendable {
    func save(_ data: [WidgetDepartureData])
    func clear()
}

extension WidgetSyncing {
    func clear() { save([]) }
}

nonisolated final class WidgetSyncManager: WidgetSyncing {
    private let appGroupID: String
    private let widgetKind: String
    private let dataKey: String
    private let lastUpdatedKey: String
    // UserDefaults is thread-safe but not Sendable; opt out explicitly.
    private nonisolated(unsafe) let storage: UserDefaults?
    
    // MARK: - Initialization
    
    init(
        appGroupID: String = "group.wellbe.TrafficVienna",
        widgetKind: String = "TrafficViennaWidget",
        dataKey: String = "widget_departure",
        lastUpdatedKey: String = "widget_last_updated"
    ) {
        self.appGroupID = appGroupID
        self.widgetKind = widgetKind
        self.dataKey = dataKey
        self.lastUpdatedKey = lastUpdatedKey
        self.storage = UserDefaults(suiteName: appGroupID)
    }
    
    func save(_ data: [WidgetDepartureData]) {
        guard let storage = storage else {
            log.error("UserDefaults not available for app group \(self.appGroupID)")
            return
        }
        let encoder = JSONEncoder()
        guard let encoded = try? encoder.encode(data) else {
            log.error("Failed to encode WidgetDepartureData")
            return
        }

        storage.set(encoded, forKey: dataKey)
        storage.set(Date(), forKey: lastUpdatedKey)

        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)

        log.debug("Saved \(data.count) items to widget")
    }

    func clear() {
        guard let storage else { return }
        [dataKey, lastUpdatedKey, "widget_last_fetch_attempt", "widget_refresh_requested_at"]
            .forEach(storage.removeObject(forKey:))
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }
}
