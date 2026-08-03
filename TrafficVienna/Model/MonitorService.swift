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
//   2. Coalescing   — concurrent requests for the same DIVA share compatible
//                     work; a user refresh behind older regular work receives
//                     one serial forced successor.
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

    private struct MonitorInFlightRequest {
        let generation: UInt64
        let isForced: Bool
        let task: Task<MonitorSnapshot, Error>
    }

    private struct TrafficInfoInFlightRequest {
        let generation: UInt64
        let isForced: Bool
        let task: Task<TrafficInfoSnapshot, Error>
    }

    private var cache: [Int: CacheEntry] = [:]
    private var inFlight: [Int: MonitorInFlightRequest] = [:]
    private var trafficInfoCache: (infos: [TrafficInfo], timestamp: Date)?
    private var trafficInfoInFlight: TrafficInfoInFlightRequest?
    private var nextRequestGeneration: UInt64 = 0
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
            return try await fetchCoalesced(diva: diva, forceRefresh: forceRefresh)
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
            return try await fetchTrafficInfoCoalesced(forceRefresh: forceRefresh)
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

    // A regular refresh may join any active request. A forced refresh only joins
    // another forced request; behind a regular request it runs one serial successor.
    private func fetchCoalesced(diva: Int, forceRefresh: Bool) async throws -> MonitorSnapshot {
        if let existing = inFlight[diva] {
            if !forceRefresh || existing.isForced {
                return try await resolve(existing, diva: diva)
            }

            // The user asked for work stronger than this regular refresh. Let it
            // finish without cancelling its waiters, then start one forced successor.
            // Concurrent forced callers will coalesce into that successor.
            _ = try? await resolve(existing, diva: diva)
            return try await fetchCoalesced(diva: diva, forceRefresh: true)
        }

        let generation = allocateRequestGeneration()
        let task = Task<MonitorSnapshot, Error> { [self] in
            try await throttle()
            let response = try await fetchWithRetry(diva: diva)
            let updatedAt = await scheduler.now()
            cache[diva] = CacheEntry(response: response, timestamp: updatedAt)
            return MonitorSnapshot(response: response, updatedAt: updatedAt, isStale: false)
        }
        let request = MonitorInFlightRequest(
            generation: generation,
            isForced: forceRefresh,
            task: task
        )
        inFlight[diva] = request
        return try await resolve(request, diva: diva)
    }

    // Traffic alerts use the same request budget and stale-data policy as station
    // monitors. Concurrent tab/badge refreshes therefore share one network call.
    private func fetchTrafficInfoCoalesced(forceRefresh: Bool) async throws -> TrafficInfoSnapshot {
        if let existing = trafficInfoInFlight {
            if !forceRefresh || existing.isForced {
                return try await resolve(existing)
            }

            _ = try? await resolve(existing)
            return try await fetchTrafficInfoCoalesced(forceRefresh: true)
        }

        let generation = allocateRequestGeneration()
        let task = Task<TrafficInfoSnapshot, Error> { [self] in
            try await throttle()
            let infos = try await fetchTrafficInfoWithRetry()
            let updatedAt = await scheduler.now()
            trafficInfoCache = (infos, updatedAt)
            return TrafficInfoSnapshot(infos: infos, updatedAt: updatedAt, isStale: false)
        }
        let request = TrafficInfoInFlightRequest(
            generation: generation,
            isForced: forceRefresh,
            task: task
        )
        trafficInfoInFlight = request
        return try await resolve(request)
    }

    // MARK: - Internals

    private func allocateRequestGeneration() -> UInt64 {
        defer { nextRequestGeneration &+= 1 }
        return nextRequestGeneration
    }

    private func resolve(
        _ request: MonitorInFlightRequest,
        diva: Int
    ) async throws -> MonitorSnapshot {
        do {
            let snapshot = try await request.task.value
            clearMonitorRequest(diva: diva, generation: request.generation)
            return snapshot
        } catch {
            clearMonitorRequest(diva: diva, generation: request.generation)
            throw error
        }
    }

    private func clearMonitorRequest(diva: Int, generation: UInt64) {
        guard inFlight[diva]?.generation == generation else { return }
        inFlight[diva] = nil
    }

    private func resolve(_ request: TrafficInfoInFlightRequest) async throws -> TrafficInfoSnapshot {
        do {
            let snapshot = try await request.task.value
            clearTrafficInfoRequest(generation: request.generation)
            return snapshot
        } catch {
            clearTrafficInfoRequest(generation: request.generation)
            throw error
        }
    }

    private func clearTrafficInfoRequest(generation: UInt64) {
        guard trafficInfoInFlight?.generation == generation else { return }
        trafficInfoInFlight = nil
    }

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
