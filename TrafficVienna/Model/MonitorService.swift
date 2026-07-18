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

nonisolated enum DataFreshness: Sendable, Equatable {
    case network(Date)
    case cache(Date)
    case stale(Date, message: String)

    var updatedAt: Date {
        switch self {
        case let .network(date), let .cache(date), let .stale(date, _): date
        }
    }

    var isStale: Bool {
        if case .stale = self { return true }
        return false
    }
}

nonisolated struct ServiceResult<Value: Sendable>: Sendable {
    let value: Value
    let freshness: DataFreshness
}

extension Error {
    // User-facing description, with a friendlier note for rate limiting.
    nonisolated var monitorDisplayMessage: String {
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

    private struct CacheEntry {
        let response: MonitorResponse
        let timestamp: Date
    }

    private var cache: [Int: CacheEntry] = [:]
    private var trafficInfoCache: (items: [TrafficInfo], timestamp: Date)?
    private var inFlight: [Int: Task<MonitorResponse, Error>] = [:]
    // Next moment a network call is allowed to start (for spacing).
    private var nextSlot = Date.distantPast

    init(
        network: NetworkManaging = NetworkManager(),
        cacheTTL: TimeInterval = 30,
        minInterval: TimeInterval = 0.5,
        maxRetries: Int = 2
    ) {
        self.network = network
        self.cacheTTL = cacheTTL
        self.minInterval = minInterval
        self.maxRetries = maxRetries
    }

    /// Returns monitor data for a station DIVA, served from cache when fresh.
    /// On a network/rate-limit failure, falls back to the last known data
    /// (even if stale) so the UI keeps showing departures instead of an error.
    /// - Parameter forceRefresh: bypass the freshness check (user refresh).
    func monitor(diva: Int, forceRefresh: Bool = false) async throws -> MonitorResponse {
        try await monitorResult(diva: diva, forceRefresh: forceRefresh).value
    }

    func monitorResult(diva: Int, forceRefresh: Bool = false) async throws -> ServiceResult<MonitorResponse> {
        if !forceRefresh, let entry = cache[diva], isFresh(entry) {
            return ServiceResult(value: entry.response, freshness: .cache(entry.timestamp))
        }

        do {
            let response = try await fetchCoalesced(diva: diva)
            if case let .urlCache(storedAt) = response.source {
                cache[diva] = CacheEntry(response: response, timestamp: storedAt)
                return ServiceResult(
                    value: response,
                    freshness: .stale(
                        storedAt,
                        message: String(localized: "No connection. Showing the most recently saved data.")
                    )
                )
            }
            let timestamp = Date()
            cache[diva] = CacheEntry(response: response, timestamp: timestamp)
            return ServiceResult(value: response, freshness: .network(timestamp))
        } catch {
            if let stale = cache[diva] {
                return ServiceResult(
                    value: stale.response,
                    freshness: .stale(stale.timestamp, message: error.monitorDisplayMessage)
                )
            }
            throw error
        }
    }

    func trafficInfoList(forceRefresh: Bool = false) async throws -> [TrafficInfo] {
        try await trafficInfoResult(forceRefresh: forceRefresh).value
    }

    func trafficInfoResult(forceRefresh: Bool = false) async throws -> ServiceResult<[TrafficInfo]> {
        if !forceRefresh, let trafficInfoCache,
           Date().timeIntervalSince(trafficInfoCache.timestamp) < cacheTTL {
            return ServiceResult(value: trafficInfoCache.items, freshness: .cache(trafficInfoCache.timestamp))
        }
        do {
            let response = try await network.fetchTrafficInfoList()
            let items = response.data.trafficInfos ?? []
            if case let .urlCache(storedAt) = response.source {
                trafficInfoCache = (items, storedAt)
                return ServiceResult(
                    value: items,
                    freshness: .stale(
                        storedAt,
                        message: String(localized: "No connection. Showing the most recently saved data.")
                    )
                )
            }
            let timestamp = Date()
            trafficInfoCache = (items, timestamp)
            return ServiceResult(value: items, freshness: .network(timestamp))
        } catch {
            if let trafficInfoCache {
                return ServiceResult(
                    value: trafficInfoCache.items,
                    freshness: .stale(trafficInfoCache.timestamp, message: error.monitorDisplayMessage)
                )
            }
            throw error
        }
    }

    func clearCache() {
        inFlight.values.forEach { $0.cancel() }
        inFlight = [:]
        cache = [:]
        trafficInfoCache = nil
        nextSlot = .distantPast
        network.removeCachedResponses()
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

    // MARK: - Internals

    private func isFresh(_ entry: CacheEntry) -> Bool {
        Date().timeIntervalSince(entry.timestamp) < cacheTTL
    }

    // Claims the next time slot and sleeps until it's due. Reading and advancing
    // `nextSlot` happens with no suspension in between, so bursts get spaced out.
    private func throttle() async throws {
        let now = Date()
        let slot = max(now, nextSlot)
        nextSlot = slot.addingTimeInterval(minInterval)

        let wait = slot.timeIntervalSince(now)
        if wait > 0 {
            try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
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
                nextSlot = Date().addingTimeInterval(backoff)
                try await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
                attempt += 1
            }
        }
    }
}
