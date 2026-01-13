//
//  WidgetSync.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 25.11.25.
//

import Foundation
import WidgetKit

protocol WidgetSyncing {
    func save(_ data: [WidgetDepartureData])
}

final class WidgetSyncManager: WidgetSyncing {
    private let appGroupID: String
    private let widgetKind: String
    private let dataKey: String
    private let lastUpdatedKey: String
    private let storage: UserDefaults?
    
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
            print("WidgetSync: UserDefaults not available for app group \(appGroupID)")
            return
        }
        let encoder = JSONEncoder()
        guard let encoded = try? encoder.encode(data) else {
            print("WidgetSync: Failed to encode WidgetDepartureData")
            return
        }
        
        storage.set(encoded, forKey: dataKey)
        storage.set(Date(), forKey: lastUpdatedKey)
        
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
        
        print("✅ WidgetSync: Saved \(data.count) items to widget")

    }
}


enum WidgetSync {
    static let appGroupID = "group.wellbe.TrafficVienna"
    static let widgetKind = "TrafficViennaWidget"
    static let widgetDataKey = "widget_departure"
    static let widgetLastUpdatedKey = "widget_last_updated"

    static func save(_ data: [WidgetDepartureData]) {
        let encoder = JSONEncoder()
        guard let encoded = try? encoder.encode(data) else {
            print("WidgetSync: failed to encode WidgetDepartureData")
            return
        }
        let defaults = UserDefaults(suiteName: appGroupID)
        defaults?.set(encoded, forKey: widgetDataKey)
        defaults?.set(Date(), forKey: widgetLastUpdatedKey)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }
}
