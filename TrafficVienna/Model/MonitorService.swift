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
//   3. Throttling   — every network attempt, including retries, is spaced at
//                     least `minInterval` apart so bursts can't flood the API.
//   4. Backoff      — monitor and traffic-info 316 responses share a growing
//                     delay before their retry re-enters the common throttle.
//   5. Bounded LRU  — only the most recently used station responses stay in
//                     memory, preventing unbounded growth during long sessions.
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
    private let retryBaseDelay: TimeInterval
    private let cacheCapacity: Int

    private struct CacheEntry {
        let response: MonitorResponse
        let timestamp: Date
    }

    private struct InFlightRequest {
        let task: Task<MonitorResponse, Error>
        var waiters: Set<UUID>
    }

    private var cache: [Int: CacheEntry] = [:]
    private var cacheRecency: [Int] = []
    private var trafficInfoCache: (items: [TrafficInfo], timestamp: Date)?
    private var inFlight: [Int: InFlightRequest] = [:]
    private var trafficInfoInFlight: InFlightRequest?
    // Next moment a network call is allowed to start (for spacing).
    private var nextSlot = Date.distantPast

    init(
        network: NetworkManaging = NetworkManager(),
        cacheTTL: TimeInterval = 30,
        minInterval: TimeInterval = 0.5,
        maxRetries: Int = 2,
        retryBaseDelay: TimeInterval = 0.8,
        cacheCapacity: Int = 64
    ) {
        precondition(cacheCapacity > 0, "Monitor cache capacity must be positive")
        precondition(retryBaseDelay >= 0, "Retry delay cannot be negative")
        self.network = network
        self.cacheTTL = cacheTTL
        self.minInterval = minInterval
        self.maxRetries = maxRetries
        self.retryBaseDelay = retryBaseDelay
        self.cacheCapacity = cacheCapacity
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
            markCacheEntryUsed(diva)
            return ServiceResult(value: entry.response, freshness: .cache(entry.timestamp))
        }

        do {
            let response = try await fetchCoalesced(diva: diva)
            if case let .urlCache(storedAt) = response.source {
                storeInCache(response, diva: diva, timestamp: storedAt)
                return ServiceResult(
                    value: response,
                    freshness: .stale(
                        storedAt,
                        message: String(localized: "No connection. Showing the most recently saved data.")
                    )
                )
            }
            let timestamp = Date()
            storeInCache(response, diva: diva, timestamp: timestamp)
            return ServiceResult(value: response, freshness: .network(timestamp))
        } catch {
            guard NetworkFallbackPolicy.allowsCachedResponse(after: error) else { throw error }
            if let stale = cache[diva] {
                markCacheEntryUsed(diva)
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
            let response = try await fetchTrafficInfoCoalesced()
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
            guard NetworkFallbackPolicy.allowsCachedResponse(after: error) else { throw error }
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
        inFlight.values.forEach { $0.task.cancel() }
        trafficInfoInFlight?.task.cancel()
        inFlight = [:]
        trafficInfoInFlight = nil
        releaseCachedResponses()
        nextSlot = .distantPast
        network.removeCachedResponses()
    }

    /// Releases decoded responses under system memory pressure without
    /// cancelling useful work or deleting the persistent URL cache.
    func releaseCachedResponses() {
        cache = [:]
        cacheRecency = []
        trafficInfoCache = nil
    }

    // Shares one in-flight request per DIVA across concurrent callers.
    private func fetchCoalesced(diva: Int) async throws -> MonitorResponse {
        let waiter = UUID()
        let task: Task<MonitorResponse, Error>
        if var existing = inFlight[diva] {
            existing.waiters.insert(waiter)
            inFlight[diva] = existing
            task = existing.task
        } else {
            task = Task<MonitorResponse, Error> { [self] in
                try await fetchWithRetry {
                    try await network.fetchMonitorData(diva: diva, includeArea: true)
                }
            }
            inFlight[diva] = InFlightRequest(task: task, waiters: [waiter])
        }

        return try await withTaskCancellationHandler {
            defer { releaseStationWaiter(waiter, diva: diva) }
            let response = try await task.value
            try Task.checkCancellation()
            return response
        } onCancel: {
            Task { await self.cancelStationWaiter(waiter, diva: diva) }
        }
    }

    // Shares the city-wide traffic-info request across dashboard and Alerts refreshes.
    private func fetchTrafficInfoCoalesced() async throws -> MonitorResponse {
        let waiter = UUID()
        let task: Task<MonitorResponse, Error>
        if var existing = trafficInfoInFlight {
            existing.waiters.insert(waiter)
            trafficInfoInFlight = existing
            task = existing.task
        } else {
            task = Task<MonitorResponse, Error> { [self] in
                try await fetchWithRetry {
                    try await network.fetchTrafficInfoList()
                }
            }
            trafficInfoInFlight = InFlightRequest(task: task, waiters: [waiter])
        }

        return try await withTaskCancellationHandler {
            defer { releaseTrafficInfoWaiter(waiter) }
            let response = try await task.value
            try Task.checkCancellation()
            return response
        } onCancel: {
            Task { await self.cancelTrafficInfoWaiter(waiter) }
        }
    }

    private func cancelStationWaiter(_ waiter: UUID, diva: Int) {
        releaseStationWaiter(waiter, diva: diva)
    }

    private func releaseStationWaiter(_ waiter: UUID, diva: Int) {
        guard var request = inFlight[diva] else { return }
        request.waiters.remove(waiter)
        if request.waiters.isEmpty {
            request.task.cancel()
            inFlight[diva] = nil
        } else {
            inFlight[diva] = request
        }
    }

    private func cancelTrafficInfoWaiter(_ waiter: UUID) {
        releaseTrafficInfoWaiter(waiter)
    }

    private func releaseTrafficInfoWaiter(_ waiter: UUID) {
        guard var request = trafficInfoInFlight else { return }
        request.waiters.remove(waiter)
        if request.waiters.isEmpty {
            request.task.cancel()
            trafficInfoInFlight = nil
        } else {
            trafficInfoInFlight = request
        }
    }

    // MARK: - Internals

    private func isFresh(_ entry: CacheEntry) -> Bool {
        Date().timeIntervalSince(entry.timestamp) < cacheTTL
    }

    private func storeInCache(_ response: MonitorResponse, diva: Int, timestamp: Date) {
        cache[diva] = CacheEntry(response: response, timestamp: timestamp)
        markCacheEntryUsed(diva)

        while cache.count > cacheCapacity, let leastRecentlyUsed = cacheRecency.first {
            cacheRecency.removeFirst()
            cache[leastRecentlyUsed] = nil
        }
    }

    private func markCacheEntryUsed(_ diva: Int) {
        cacheRecency.removeAll { $0 == diva }
        cacheRecency.append(diva)
    }

    // Waits until the current slot is available and only then claims the next
    // one. Cancelled sleepers therefore leave no phantom reservations behind.
    private func throttle() async throws {
        while true {
            try Task.checkCancellation()
            let now = Date()
            let wait = nextSlot.timeIntervalSince(now)
            if wait <= 0 {
                nextSlot = now.addingTimeInterval(minInterval)
                return
            }
            try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
        }
    }

    private func fetchWithRetry(
        operation: @Sendable () async throws -> MonitorResponse
    ) async throws -> MonitorResponse {
        var attempt = 0
        while true {
            try await throttle()
            do {
                return try await operation()
            } catch MonitorApiError.rateLimited {
                guard attempt < maxRetries else { throw MonitorApiError.rateLimited }
                let backoff = pow(2.0, Double(attempt)) * retryBaseDelay
                // Push the shared slot out so other queued calls also wait.
                let backoffSlot = Date().addingTimeInterval(backoff)
                if nextSlot < backoffSlot {
                    nextSlot = backoffSlot
                }
                if backoff > 0 {
                    try await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
                }
                attempt += 1
            }
        }
    }
}
