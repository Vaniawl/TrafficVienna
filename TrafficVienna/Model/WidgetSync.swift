//
//  WidgetSync.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 25.11.25.
//

import Foundation
import WidgetKit

enum WidgetSync {
    static let appGroupID = "group.wellbe.TrafficVienna"
    
    static let widgetKind = "TrafficViennaWidget"

    static func save(_ data: [WidgetDepartureData]) {
        let encoder = JSONEncoder()
        guard let encoded = try? encoder.encode(data) else {
            print("WidgetSync: failed to encode WidgetDepartureData")
            return
        }
        let defaults = UserDefaults(suiteName: appGroupID)
        defaults?.set(encoded, forKey: "widget_departure")
        
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }
}
