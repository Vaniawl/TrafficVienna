//
//  DepartureTime+Live.swift
//  TrafficVienna
//
//  Computes a live countdown from a departure's timestamp so the displayed
//  minutes keep decreasing between network refreshes, instead of showing the
//  static value captured at fetch time.
//

import Foundation

enum DepartureClock {
    private nonisolated(unsafe) static let fractionalFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private nonisolated(unsafe) static let standardFormatter = ISO8601DateFormatter()

    // Minutes from now until departure, preferring the real-time instant.
    // Falls back to `fallback` when no timestamp can be parsed (e.g. mock data).
    static func liveMinutes(realtime: String?, planned: String?, fallback: Int) -> Int {
        guard let raw = realtime ?? planned else { return fallback }
        guard let date = fractionalFormatter.date(from: raw) ?? standardFormatter.date(from: raw) else {
            return fallback
        }
        return max(0, Int(ceil(date.timeIntervalSinceNow / 60)))
    }
}

extension DepartureTime {
    var liveMinutes: Int {
        DepartureClock.liveMinutes(realtime: timeReal, planned: timePlanned, fallback: countdown)
    }
}

extension DepartureInfo {
    var liveMinutes: Int {
        DepartureClock.liveMinutes(realtime: real, planned: planned, fallback: countdown)
    }
}
