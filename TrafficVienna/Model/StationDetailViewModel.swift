//
//  StationDetailViewModel.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 13.11.25.
//

import Foundation
import Combine


final class StationDetailViewModel: ObservableObject {
    let station: Station
    private let service: MonitorService
    private let widgetSync: WidgetSyncing
    private var isRequesting = false
    private var loadGeneration = 0

    @Published var isLoading = false
    @Published private(set) var isRefreshing = false
    @Published var errorMessage: String?
    @Published var monitor: MonitorResponse?
    @Published var lastUpdated: Date?
    @Published var categoryFilter: LineCategory? = nil
    @Published private(set) var freshness: DataFreshness?
    private var allGroups: [DepartureGroup] = []
    private var affectedLineNames: Set<String> = []
    private(set) var availableCategories: [LineCategory] = []

    // Active disruptions / notices for this station's lines.
    var trafficInfos: [TrafficInfo] {
        monitor?.data.trafficInfos ?? []
    }

    func hasDisruption(lineName: String) -> Bool {
        affectedLineNames.contains(lineName)
    }

    // One departure direction at the station.
    nonisolated struct DepartureGroup: Identifiable, Sendable {
        let line: String
        let destination: String
        let minutes: [Int]   // live, ascending
        let isLive: Bool
        var id: String { line + "|" + destination }
    }

    nonisolated private struct DerivedContent: Sendable {
        static let empty = DerivedContent(
            groups: [],
            availableCategories: [],
            affectedLineNames: []
        )

        let groups: [DepartureGroup]
        let availableCategories: [LineCategory]
        let affectedLineNames: Set<String>
    }

    // All departures across every platform, merged by line+direction and
    // sorted so the soonest one is first. Replaces the per-platform grouping
    // that produced repeated "<station>" section headers.
    var groups: [DepartureGroup] {
        guard let filter = categoryFilter else { return allGroups }
        return allGroups.filter { LineCategory.of($0.line) == filter }
    }

    nonisolated private static func makeDerivedContent(from response: MonitorResponse) -> DerivedContent {
        var merged: [String: (line: String, dest: String, mins: [Int], live: Bool)] = [:]
        var order: [String] = []
        var presentCategories = Set<LineCategory>()
        presentCategories.reserveCapacity(LineCategory.allCases.count)
        var affectedLineNames = Set<String>()

        for info in response.data.trafficInfos ?? [] {
            for line in info.relatedLines ?? [] {
                affectedLineNames.insert(line)
            }
        }

        for platform in response.data.monitors {
            guard !Task.isCancelled else { return .empty }
            for line in platform.lines {
                presentCategories.insert(LineCategory.of(line.name))
                let key = line.name + "|" + line.towards
                let mins = line.departures.departure.map { $0.departureTime.liveMinutes }
                let live = line.departures.departure.first?.departureTime.timeReal != nil
                if var existing = merged[key] {
                    existing.mins += mins
                    existing.live = existing.live || live
                    merged[key] = existing
                } else {
                    merged[key] = (line.name, line.towards, mins, live)
                    order.append(key)
                }
            }
        }

        var groups: [DepartureGroup] = []
        groups.reserveCapacity(order.count)
        for key in order {
            guard let group = merged[key] else { continue }
            groups.append(DepartureGroup(
                line: group.line,
                destination: group.dest,
                minutes: group.mins.sorted(),
                isLive: group.live
            ))
        }
        groups.sort { ($0.minutes.first ?? .max) < ($1.minutes.first ?? .max) }

        return DerivedContent(
            groups: groups,
            availableCategories: LineCategory.allCases.filter(presentCategories.contains),
            affectedLineNames: affectedLineNames
        )
    }

    private func apply(_ content: DerivedContent) {
        allGroups = content.groups
        availableCategories = content.availableCategories
        affectedLineNames = content.affectedLineNames
    }

    var lastUpdatedText: String? {
        guard let lastUpdated else { return nil }
        let seconds = Int(Date().timeIntervalSince(lastUpdated))
        switch seconds {
        case ..<10:    return "updated just now"
        case ..<60:    return "updated \(seconds)s ago"
        case ..<3600:  return "updated \(seconds / 60)m ago"
        default:       return "updated \(seconds / 3600)h ago"
        }
    }

    init(
        station: Station,
        service: MonitorService = .shared,
        widgetSync: WidgetSyncing = WidgetSyncManager()
    ) {
        self.station = station
        self.service = service
        self.widgetSync = widgetSync
    }

    // Loads live monitor data for the current station's DIVA.
    @MainActor
    func load(forceRefresh: Bool = false) async {
        guard forceRefresh || !isRequesting else { return }
        loadGeneration &+= 1
        let generation = loadGeneration
        isRequesting = true
        errorMessage = nil
        if monitor == nil { isLoading = true } else { isRefreshing = true }

        defer {
            if generation == loadGeneration {
                isRequesting = false
                isLoading = false
                isRefreshing = false
            }
        }
        guard let diva = station.diva else {
            errorMessage = "No live data for this station"
            return
        }

        do {
            let result = try await service.monitorResult(diva: diva, forceRefresh: forceRefresh)
            guard !Task.isCancelled, generation == loadGeneration else { return }
            let transformTask = Task.detached(priority: .userInitiated) {
                Self.makeDerivedContent(from: result.value)
            }
            let derivedContent = await withTaskCancellationHandler {
                await transformTask.value
            } onCancel: {
                transformTask.cancel()
            }
            guard !Task.isCancelled, generation == loadGeneration else { return }
            apply(derivedContent)
            self.monitor = result.value
            self.freshness = result.freshness
            self.lastUpdated = result.freshness.updatedAt
            if let widgetData = widgetData(from: result.value) {
                widgetSync.save([widgetData])
            }
        } catch {
            guard !Task.isCancelled, generation == loadGeneration else { return }
            errorMessage = error.monitorDisplayMessage
        }
    }

    var staleMessage: String? {
        guard case let .stale(_, message) = freshness else { return nil }
        return message
    }
    
    private func widgetData(from response: MonitorResponse) -> WidgetDepartureData? {
        guard let monitor = response.data.monitors.first else {
            return nil
        }
        guard let line = monitor.lines.first else {
            return nil
        }
        let lineName = line.name
        let stopName = monitor.locationStop.properties.title
        let destination = line.towards
        let allDepartures = line.departures.departure
        let minutes = allDepartures.map { $0.departureTime.countdown }
        let nextThree = Array(minutes.prefix(3))
        
        return WidgetDepartureData(
            lineName: lineName, stopName: stopName, destination: destination, departures: nextThree
        )
    }
}
