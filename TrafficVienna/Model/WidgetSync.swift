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
    private let dataKey: String
    private let lastUpdatedKey: String
    private let reloadTimelines: @Sendable () -> Void
    private let lock = NSLock()
    // UserDefaults is thread-safe but not Sendable; opt out explicitly.
    private nonisolated(unsafe) let storage: UserDefaults?
    
    // MARK: - Initialization
    
    init(
        appGroupID: String = "group.wellbe.TrafficVienna",
        widgetKind: String = "TrafficViennaWidget",
        dataKey: String = "widget_departure",
        lastUpdatedKey: String = "widget_last_updated",
        storage: UserDefaults? = nil,
        reloadTimelines: (@Sendable () -> Void)? = nil
    ) {
        self.appGroupID = appGroupID
        self.dataKey = dataKey
        self.lastUpdatedKey = lastUpdatedKey
        self.storage = storage ?? UserDefaults(suiteName: appGroupID)
        self.reloadTimelines = reloadTimelines ?? {
            WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
        }
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

        let didChange = lock.withLock {
            if let stored = storage.data(forKey: dataKey),
               let current = try? JSONDecoder().decode([WidgetDepartureData].self, from: stored),
               current == data {
                return false
            }
            storage.set(encoded, forKey: dataKey)
            storage.set(Date(), forKey: lastUpdatedKey)
            return true
        }

        guard didChange else {
            log.debug("Skipped unchanged widget data")
            return
        }

        reloadTimelines()

        log.debug("Saved \(data.count) items to widget")
    }

    func clear() {
        guard let storage else { return }
        lock.withLock {
            [dataKey, lastUpdatedKey, "widget_last_fetch_attempt", "widget_refresh_requested_at"]
                .forEach(storage.removeObject(forKey:))
        }
        reloadTimelines()
    }
}
