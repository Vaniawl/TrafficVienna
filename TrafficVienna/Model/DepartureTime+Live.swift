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
    private nonisolated(unsafe) static let fractionalISOFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private nonisolated(unsafe) static let isoFormatter = ISO8601DateFormatter()

    static func departureDate(realtime: String?, planned: String?) -> Date? {
        guard let raw = realtime ?? planned,
              let date = fractionalISOFormatter.date(from: raw) ?? isoFormatter.date(from: raw)
        else { return nil }
        return date
    }

    // Minutes from now until departure, preferring the real-time instant.
    // Falls back to `fallback` when no timestamp can be parsed (e.g. mock data).
    static func liveMinutes(realtime: String?, planned: String?, fallback: Int) -> Int {
        liveMinutes(
            departureDate: departureDate(realtime: realtime, planned: planned),
            fallback: fallback
        )
    }

    static func liveMinutes(departureDate: Date?, fallback: Int) -> Int {
        liveMinutes(departureDate: departureDate, fallback: fallback, now: .now)
    }

    static func liveMinutes(departureDate: Date?, fallback: Int, now: Date) -> Int {
        guard let departureDate else { return fallback }
        return max(0, Int(ceil(departureDate.timeIntervalSince(now) / 60)))
    }
}

extension DepartureTime {
    var liveMinutes: Int {
        DepartureClock.liveMinutes(realtime: timeReal, planned: timePlanned, fallback: countdown)
    }
}

extension DepartureInfo {
    var liveMinutes: Int {
        DepartureClock.liveMinutes(departureDate: departureDate, fallback: countdown)
    }
}
