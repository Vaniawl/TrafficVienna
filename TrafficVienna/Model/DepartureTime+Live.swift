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
    private static let nowDisplayDuration: TimeInterval = 60

    private nonisolated(unsafe) static let fractionalFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private nonisolated(unsafe) static let standardFormatter = ISO8601DateFormatter()

    // Minutes from now until departure, preferring the real-time instant.
    // A departure remains visible as `now` for one minute, then becomes nil so
    // stale responses cannot keep an already-departed service on screen.
    // Timestamp-free feeds project their countdown from the response timestamp.
    static func liveMinutes(
        realtime: String?,
        planned: String?,
        fallback: Int,
        anchoredAt: Date? = nil,
        now: Date = .now
    ) -> Int? {
        if let departureDate = parsedDate(realtime) ?? parsedDate(planned) {
            return projectedMinutes(until: departureDate, at: now)
        }

        guard fallback >= 0 else { return nil }
        guard let anchoredAt else { return fallback }
        let departureDate = anchoredAt.addingTimeInterval(TimeInterval(fallback) * 60)
        return projectedMinutes(until: departureDate, at: now)
    }

    private static func parsedDate(_ raw: String?) -> Date? {
        guard let raw else { return nil }
        return fractionalFormatter.date(from: raw) ?? standardFormatter.date(from: raw)
    }

    private static func projectedMinutes(until departureDate: Date, at now: Date) -> Int? {
        let remaining = departureDate.timeIntervalSince(now)
        guard remaining > -nowDisplayDuration else { return nil }
        return max(0, Int(ceil(remaining / 60)))
    }
}

extension DepartureTime {
    func liveMinutes(anchoredAt: Date? = nil, now: Date = .now) -> Int? {
        DepartureClock.liveMinutes(
            realtime: timeReal,
            planned: timePlanned,
            fallback: countdown,
            anchoredAt: anchoredAt,
            now: now
        )
    }
}

extension DepartureInfo {
    func liveMinutes(anchoredAt: Date? = nil, now: Date = .now) -> Int? {
        DepartureClock.liveMinutes(
            realtime: real,
            planned: planned,
            fallback: countdown,
            anchoredAt: anchoredAt,
            now: now
        )
    }
}
