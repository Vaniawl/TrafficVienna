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
    // Shared parser. ISO8601DateFormatter is safe for concurrent reads, so the
    // unsafe opt-out is acceptable here.
    private nonisolated(unsafe) static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    // Minutes from now until departure, preferring the real-time instant.
    // Falls back to `fallback` when no timestamp can be parsed (e.g. mock data).
    static func liveMinutes(realtime: String?, planned: String?, fallback: Int) -> Int {
        guard let raw = realtime ?? planned,
              let date = isoFormatter.date(from: raw) else { return fallback }
        return max(0, Int(date.timeIntervalSinceNow / 60))
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
