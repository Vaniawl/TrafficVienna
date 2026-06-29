//
//  RelativeTime.swift
//  TrafficVienna
//
//  Shared, localized "updated N ago" formatting used by the station detail,
//  favourites and nearby-card freshness indicators.
//

import Foundation

enum RelativeTime {
    static func updated(since date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        switch seconds {
        case ..<10:   return String(localized: "updated just now")
        case ..<60:   return String(localized: "updated \(seconds)s ago")
        case ..<3600: return String(localized: "updated \(seconds / 60)m ago")
        default:      return String(localized: "updated \(seconds / 3600)h ago")
        }
    }
}
