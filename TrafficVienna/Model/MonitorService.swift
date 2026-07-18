//
//  MonitorService.swift
//  TrafficVienna
//
//  Single point of access to live monitor data. Sits between the view models
//  and NetworkManager and keeps the app within the Wiener Linien request
//  limit through four mechanisms:
//
//   1. Caching      — responses are reused for `cacheTTL` seconds (the feed
//                     itself only updates every ~15-30s, so this is free).
//   2. Coalescing   — concurrent requests for the same DIVA share one network
//                     call instead of firing several.
//   3. Throttling   — actual network calls are spaced at least `minInterval`
//                     apart, so a burst of nearby cards can't flood the API.
//   4. Backoff      — a 316 (rate limited) response is retried with growing
//                     delays before giving up.
//

import Foundation

extension Error {
    // User-facing description, with a friendlier note for rate limiting.
    var monitorDisplayMessage: String {
        if self is MonitorApiError {
            return String(localized: "Service is busy right now. Please try again in a moment.")
        }
        let nsError = self as NSError
        if nsError.domain == NSURLErrorDomain {
            return String(localized: "No connection. Check your internet and try again.")
        }
        return nsError.localizedDescription
    }
}

actor MonitorService {
    static let shared = MonitorService()

    private let network: NetworkManaging
    private let cacheTTL: TimeInterval
    private let minInterval: TimeInterval
    private let maxRetries: Int
    private let scheduler: MonitorScheduling

    private struct CacheEntry {
        let response: MonitorResponse
        let timestamp: Date
    }

    private var cache: [Int: CacheEntry] = [:]
    private var inFlight: [Int: Task<MonitorResponse, Error>] = [:]
    private var trafficInfoCache: (infos: [TrafficInfo], timestamp: Date)?
    private var trafficInfoInFlight: Task<[TrafficInfo], Error>?
    // Next moment a network call is allowed to start (for spacing).
    private var nextSlot = Date.distantPast

    init(
        network: NetworkManaging = NetworkManager(),
        cacheTTL: TimeInterval = 30,
        minInterval: TimeInterval = 0.5,
        maxRetries: Int = 2,
        scheduler: MonitorScheduling = SystemMonitorScheduler()
    ) {
        self.network = network
        self.cacheTTL = cacheTTL
        self.minInterval = minInterval
        self.maxRetries = maxRetries
        self.scheduler = scheduler
    }

    /// Returns monitor data for a station DIVA, served from cache when fresh.
    /// On a network/rate-limit failure, falls back to the last known data
    /// (even if stale) so the UI keeps showing departures instead of an error.
    /// - Parameter forceRefresh: bypass the freshness check (user refresh).
    func monitor(diva: Int, forceRefresh: Bool = false) async throws -> MonitorResponse {
        try await monitorSnapshot(diva: diva, forceRefresh: forceRefresh).response
    }

    func monitorSnapshot(diva: Int, forceRefresh: Bool = false) async throws -> MonitorSnapshot {
        let now = await scheduler.now()
        if !forceRefresh, let entry = cache[diva], isFresh(entry, now: now) {
            return MonitorSnapshot(response: entry.response, updatedAt: entry.timestamp, isStale: false)
        }

        do {
            let response = try await fetchCoalesced(diva: diva)
            let updatedAt = await scheduler.now()
            cache[diva] = CacheEntry(response: response, timestamp: updatedAt)
            return MonitorSnapshot(response: response, updatedAt: updatedAt, isStale: false)
        } catch {
            if let stale = cache[diva] {
                return MonitorSnapshot(response: stale.response, updatedAt: stale.timestamp, isStale: true)
            }
            throw error
        }
    }

    func trafficInfoList(forceRefresh: Bool = false) async throws -> [TrafficInfo] {
        try await trafficInfoSnapshot(forceRefresh: forceRefresh).infos
    }

    func trafficInfoSnapshot(forceRefresh: Bool = false) async throws -> TrafficInfoSnapshot {
        let now = await scheduler.now()
        if !forceRefresh,
           let trafficInfoCache,
           now.timeIntervalSince(trafficInfoCache.timestamp) < cacheTTL {
            return TrafficInfoSnapshot(
                infos: trafficInfoCache.infos,
                updatedAt: trafficInfoCache.timestamp,
                isStale: false
            )
        }

        do {
            let infos = try await fetchTrafficInfoCoalesced()
            let updatedAt = await scheduler.now()
            trafficInfoCache = (infos, updatedAt)
            return TrafficInfoSnapshot(infos: infos, updatedAt: updatedAt, isStale: false)
        } catch {
            if let trafficInfoCache {
                return TrafficInfoSnapshot(
                    infos: trafficInfoCache.infos,
                    updatedAt: trafficInfoCache.timestamp,
                    isStale: true
                )
            }
            throw error
        }
    }

    // Shares one in-flight request per DIVA across concurrent callers.
    private func fetchCoalesced(diva: Int) async throws -> MonitorResponse {
        if let existing = inFlight[diva] {
            return try await existing.value
        }
        let task = Task<MonitorResponse, Error> { [self] in
            try await throttle()
            return try await fetchWithRetry(diva: diva)
        }
        inFlight[diva] = task
        defer { inFlight[diva] = nil }
        return try await task.value
    }

    // Traffic alerts use the same request budget and stale-data policy as station
    // monitors. Concurrent tab/badge refreshes therefore share one network call.
    private func fetchTrafficInfoCoalesced() async throws -> [TrafficInfo] {
        if let trafficInfoInFlight {
            return try await trafficInfoInFlight.value
        }
        let task = Task<[TrafficInfo], Error> { [self] in
            try await throttle()
            return try await fetchTrafficInfoWithRetry()
        }
        trafficInfoInFlight = task
        defer { trafficInfoInFlight = nil }
        return try await task.value
    }

    // MARK: - Internals

    private func isFresh(_ entry: CacheEntry, now: Date) -> Bool {
        now.timeIntervalSince(entry.timestamp) < cacheTTL
    }

    // Claims the next time slot and sleeps until it's due. Reading and advancing
    // `nextSlot` happens with no suspension in between, so bursts get spaced out.
    private func throttle() async throws {
        let now = await scheduler.now()
        let slot = max(now, nextSlot)
        nextSlot = slot.addingTimeInterval(minInterval)

        let wait = slot.timeIntervalSince(now)
        if wait > 0 {
            try await scheduler.sleep(for: .seconds(wait))
        }
    }

    private func fetchWithRetry(diva: Int) async throws -> MonitorResponse {
        var attempt = 0
        while true {
            do {
                return try await network.fetchMonitorData(diva: diva, includeArea: true)
            } catch MonitorApiError.rateLimited {
                guard attempt < maxRetries else { throw MonitorApiError.rateLimited }
                let backoff = pow(2.0, Double(attempt)) * 0.8 // 0.8s, 1.6s, …
                // Push the shared slot out so other queued calls also wait.
                let now = await scheduler.now()
                nextSlot = max(nextSlot, now.addingTimeInterval(backoff))
                try await scheduler.sleep(for: .seconds(backoff))
                attempt += 1
            }
        }
    }

    private func fetchTrafficInfoWithRetry() async throws -> [TrafficInfo] {
        var attempt = 0
        while true {
            do {
                return try await network.fetchTrafficInfoList().data.trafficInfos ?? []
            } catch MonitorApiError.rateLimited {
                guard attempt < maxRetries else { throw MonitorApiError.rateLimited }
                let backoff = pow(2.0, Double(attempt)) * 0.8
                let now = await scheduler.now()
                nextSlot = max(nextSlot, now.addingTimeInterval(backoff))
                try await scheduler.sleep(for: .seconds(backoff))
                attempt += 1
            }
        }
    }
}
