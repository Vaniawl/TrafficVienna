//
//  NearbyViewModel.swift
//  TrafficVienna
//
//  Coordinates the Nearby tab. Instead of each card firing its own request
//  (which used to flood the API), this loads the nearby stations *sequentially*
//  through the shared, throttled MonitorService, tracks a single "last updated"
//  time and supports manual refresh.
//

import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
final class NearbyViewModel {
    struct Item: Identifiable {
        let station: Station
        let distance: Double
        var lines: [Lines] = []
        var failed: Bool = false
        var updatedAt: Date? = nil
        var isStale = false

        var id: Int { station.id }
        var walkMinutes: Int { max(1, Int((distance / walkingSpeed).rounded())) }
    }

    private struct LocationKey: Equatable {
        let latitude: CLLocationDegrees
        let longitude: CLLocationDegrees

        init?(_ location: CLLocation?) {
            guard let location else { return nil }
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
        }
    }

    private struct LoadRequest {
        let location: CLLocation?
        let forceRefresh: Bool

        private var locationKey: LocationKey? {
            LocationKey(location)
        }

        func isSatisfied(by activeRequest: LoadRequest) -> Bool {
            !forceRefresh && locationKey == activeRequest.locationKey
        }

        func merging(with newerRequest: LoadRequest) -> LoadRequest {
            LoadRequest(
                location: newerRequest.location,
                forceRefresh: forceRefresh || newerRequest.forceRefresh
            )
        }
    }

    private(set) var items: [Item] = []
    private(set) var isLoading = false      // first fill, nothing to show yet
    private(set) var isRefreshing = false   // updating already-shown data

    private let store: StationStoring
    private let location: LocationProviding
    private let service: MonitorProviding
    private let radius: Double = 500
    private let maxStations = 8
    @ObservationIgnored private var activeLoadRequest: LoadRequest?
    @ObservationIgnored private var queuedLoadRequest: LoadRequest?
    @ObservationIgnored private var loadCompletionWaiters: [CheckedContinuation<Bool, Never>] = []

    init(
        store: StationStoring,
        location: LocationProviding,
        service: MonitorProviding = MonitorService.shared
    ) {
        self.store = store
        self.location = location
        self.service = service
    }

    var hasLocation: Bool { location.userLocation != nil }

    // Rebuilds the nearby list from the current location, keeping already-loaded
    // departures for stations that are still in range.
    private func rebuildList(at location: CLLocation?) {
        guard let location else {
            items = []
            return
        }
        let previous = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        items = store.stations(near: location, radiusInMeters: radius)
            .map { (station: $0, distance: CLLocation(latitude: $0.lat, longitude: $0.lon).distance(from: location)) }
            .sorted { $0.distance < $1.distance }
            .prefix(maxStations)
            .map { pair in
                Item(station: pair.station,
                     distance: pair.distance,
                     lines: previous[pair.station.id]?.lines ?? [],
                     failed: false,
                     updatedAt: previous[pair.station.id]?.updatedAt,
                     isStale: previous[pair.station.id]?.isStale ?? false)
            }
    }

    func load(force: Bool = false) async {
        var request = LoadRequest(
            location: location.userLocation,
            forceRefresh: force
        )

        while true {
            if let activeLoadRequest {
                if !request.isSatisfied(by: activeLoadRequest) {
                    enqueue(request)
                }

                let existingChainFulfilledRequest = await waitForActiveLoad()
                guard !Task.isCancelled else { return }
                if existingChainFulfilledRequest { return }

                request = LoadRequest(
                    location: location.userLocation,
                    forceRefresh: request.forceRefresh
                )
                continue
            }

            await runLoadChain(startingWith: request)
            return
        }
    }

    private func runLoadChain(startingWith initialRequest: LoadRequest) async {
        precondition(activeLoadRequest == nil)
        activeLoadRequest = initialRequest
        defer {
            let fulfilledWaitingRequests = !Task.isCancelled && queuedLoadRequest == nil
            activeLoadRequest = nil
            queuedLoadRequest = nil
            isLoading = false
            isRefreshing = false
            resumeLoadCompletionWaiters(fulfilled: fulfilledWaitingRequests)
        }

        var nextRequest: LoadRequest? = initialRequest
        while let request = nextRequest {
            activeLoadRequest = request
            queuedLoadRequest = nil
            await loadPass(request)
            guard !Task.isCancelled else { return }
            nextRequest = queuedLoadRequest
        }
    }

    private func loadPass(_ request: LoadRequest) async {
        rebuildList(at: request.location)
        guard !items.isEmpty else { return }

        let firstFill = items.allSatisfy { $0.lines.isEmpty }
        isLoading = firstFill
        isRefreshing = !firstFill

        // Sequential: each await naturally spaces requests for the API.
        for item in items {
            guard !Task.isCancelled else { return }
            guard queuedLoadRequest == nil else { return }
            guard let diva = item.station.diva else { continue }
            do {
                let snapshot = try await service.monitorSnapshot(
                    diva: diva,
                    forceRefresh: request.forceRefresh
                )
                guard !Task.isCancelled else { return }
                guard queuedLoadRequest == nil else { return }
                update(id: item.id) {
                    $0.lines = snapshot.response.data.monitors.flatMap { $0.lines }
                    $0.failed = false
                    $0.updatedAt = snapshot.updatedAt
                    $0.isStale = snapshot.isStale
                }
            } catch {
                guard !Task.isCancelled else { return }
                guard queuedLoadRequest == nil else { return }
                update(id: item.id) {
                    $0.failed = true
                    $0.isStale = !$0.lines.isEmpty
                }
            }
        }
    }

    private func enqueue(_ request: LoadRequest) {
        if let queuedLoadRequest {
            self.queuedLoadRequest = queuedLoadRequest.merging(with: request)
        } else {
            queuedLoadRequest = request
        }
    }

    private func waitForActiveLoad() async -> Bool {
        await withCheckedContinuation { continuation in
            loadCompletionWaiters.append(continuation)
        }
    }

    private func resumeLoadCompletionWaiters(fulfilled: Bool) {
        let waiters = loadCompletionWaiters
        loadCompletionWaiters.removeAll()
        waiters.forEach { $0.resume(returning: fulfilled) }
    }

    private func update(id: Int, _ mutate: (inout Item) -> Void) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        mutate(&items[index])
    }
}
