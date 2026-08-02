import CoreLocation
import XCTest
@testable import TrafficVienna

final class TrafficViennaTests: XCTestCase {

    // MARK: - StationStore

    func testLoadStationsNotEmpty() {
        let store = StationStore()

        XCTAssertEqual(store.loadState, .loaded)
        XCTAssertGreaterThan(store.stations.count, 0)
    }

    func testIndexedStationSearchMatchesCatalogOrder() {
        let store = StationStore()
        let expected = store.stations.filter {
            $0.name.folding(options: .diacriticInsensitive, locale: .current)
                .replacing("ß", with: "ss")
                .lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedStandardContains("schotten")
        }

        XCTAssertEqual(store.stationsSuggestion(matching: "Schotten"), expected)
    }

    func testIndexedStationSearchFoldsDiacritics() {
        let store = StationStore()

        XCTAssertTrue(
            store.stationsSuggestion(matching: "hutteldorf")
                .contains { $0.name == "Hütteldorf" }
        )
        XCTAssertTrue(
            store.stationsSuggestion(matching: "schonbrunn")
                .contains { $0.name == "Schönbrunn" }
        )
    }

    func testIndexedNearbySearchMatchesFullDistanceScan() {
        let store = StationStore()
        let center = CLLocation(latitude: 48.2082, longitude: 16.3738)
        let radius = 1_500.0
        let expected = store.stations.filter {
            CLLocation(latitude: $0.lat, longitude: $0.lon)
                .distance(from: center) <= radius
        }

        XCTAssertEqual(
            Set(store.stations(near: center, radiusInMeters: radius)),
            Set(expected)
        )
    }

    // MARK: - RouteMatching

    func testNormalizeTrimsWhitespace() {
        XCTAssertEqual(RouteMatching.normalize("  Praterstern  "), "praterstern")
    }

    func testNormalizeLowercases() {
        XCTAssertEqual(RouteMatching.normalize("Leopoldau"), "leopoldau")
    }

    func testNormalizeStripsTrailingU() {
        XCTAssertEqual(RouteMatching.normalize("Kagran U"), "kagran")
    }

    func testNormalizeStripsTrailingS() {
        XCTAssertEqual(RouteMatching.normalize("Meidling S"), "meidling")
    }

    func testNormalizeDoesNotStripMidStringU() {
        XCTAssertEqual(RouteMatching.normalize("Wien Mitte"), "wien mitte")
    }

    func testNormalizeCollapsesInternalWhitespace() {
        XCTAssertEqual(RouteMatching.normalize("Wien   Mitte"), "wien mitte")
    }

    func testNormalizeFoldsDiacritics() {
        XCTAssertEqual(RouteMatching.normalize("Franz-Josefs-Bahnhof"), "franz-josefs-bahnhof")
    }

    func testMatchesExact() {
        XCTAssertTrue(RouteMatching.matches(
            lineName: "U1", towards: "Leopoldau",
            favoriteLine: "U1", favoriteDestination: "Leopoldau"
        ))
    }

    func testMatchesWithTrailingMarker() {
        XCTAssertTrue(RouteMatching.matches(
            lineName: "U1", towards: "Leopoldau U",
            favoriteLine: "U1", favoriteDestination: "Leopoldau"
        ))
    }

    func testMatchesDifferentLineFails() {
        XCTAssertFalse(RouteMatching.matches(
            lineName: "U1", towards: "Leopoldau",
            favoriteLine: "U2", favoriteDestination: "Leopoldau"
        ))
    }

    func testMatchesDifferentDestinationFails() {
        XCTAssertFalse(RouteMatching.matches(
            lineName: "U1", towards: "Leopoldau",
            favoriteLine: "U1", favoriteDestination: "Kagran"
        ))
    }

    // MARK: - DepartureClock

    func testLiveMinutesFallback() {
        let result = DepartureClock.liveMinutes(realtime: nil, planned: nil, fallback: 42)
        XCTAssertEqual(result, 42)
    }

    func testLiveMinutesFromRealTime() {
        let future = ISO8601DateFormatter().string(from: Date().addingTimeInterval(300))
        let result = DepartureClock.liveMinutes(realtime: future, planned: nil, fallback: 99)
        XCTAssertEqual(result, 5)
    }

    func testLiveMinutesFromPlanned() {
        let future = ISO8601DateFormatter().string(from: Date().addingTimeInterval(120))
        let result = DepartureClock.liveMinutes(realtime: nil, planned: future, fallback: 99)
        XCTAssertEqual(result, 2)
    }

    func testLiveMinutesNeverNegative() {
        let past = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-60))
        let result = DepartureClock.liveMinutes(realtime: nil, planned: past, fallback: 0)
        XCTAssertEqual(result, 0)
    }

    func testLiveActivityLifecycleEndsTwoMinutesAfterDeparture() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let departure = DepartureActivityLifecycle.departureDate(
            minutes: 5,
            now: now
        )
        let end = DepartureActivityLifecycle.automaticEndDate(
            departureDate: departure
        )

        XCTAssertEqual(departure, now.addingTimeInterval(5 * 60))
        XCTAssertEqual(end, now.addingTimeInterval(7 * 60))
        XCTAssertFalse(
            DepartureActivityLifecycle.isExpired(
                departureDate: departure,
                now: end.addingTimeInterval(-1)
            )
        )
        XCTAssertTrue(
            DepartureActivityLifecycle.isExpired(
                departureDate: departure,
                now: end
            )
        )
    }

    // MARK: - DepartureTime liveMinutes

    func testDepartureTimeLiveMinutesFallback() {
        let dt = DepartureTime(countdown: 7, timePlanned: nil, timeReal: nil)
        XCTAssertEqual(dt.liveMinutes, 7)
    }

    // MARK: - MonitorService (mock network)

    func testMonitorServiceReturnsCachedResponse() async throws {
        let mock = MockNetworkManager()
        let service = MonitorService(network: mock, cacheTTL: 30)

        let first = try await service.monitor(diva: 60201435)
        let cached = try await service.monitor(diva: 60201435)
        let callCount = await mock.callCount

        XCTAssertEqual(first.data.monitors.count, cached.data.monitors.count)
        XCTAssertEqual(callCount, 1, "Second call should hit cache, not network")
    }

    func testMonitorServiceForceRefreshBypassesCache() async throws {
        let mock = MockNetworkManager()
        let service = MonitorService(network: mock, cacheTTL: 30)

        _ = try await service.monitor(diva: 60201435)
        _ = try await service.monitor(diva: 60201435, forceRefresh: true)
        let callCount = await mock.callCount

        XCTAssertEqual(callCount, 2, "Force refresh should bypass cache")
    }

    func testMonitorServiceFallbackToStaleCacheOnNetworkError() async throws {
        let mock = MockNetworkManager()
        let service = MonitorService(network: mock, cacheTTL: 0)

        let current = try await service.monitorSnapshot(diva: 60201435)
        await mock.setShouldFail(true)

        let result = try await service.monitorSnapshot(diva: 60201435)
        XCTAssertFalse(result.response.data.monitors.isEmpty, "Should return stale cache on error")
        XCTAssertTrue(result.isStale)
        XCTAssertEqual(result.updatedAt, current.updatedAt)
    }

    func testTrafficInfoListUsesCache() async throws {
        let mock = MockNetworkManager()
        let service = MonitorService(network: mock, cacheTTL: 30)

        _ = try await service.trafficInfoList()
        _ = try await service.trafficInfoList()
        let callCount = await mock.callCount

        XCTAssertEqual(callCount, 1)
    }

    func testTrafficInfoListForceRefreshBypassesCache() async throws {
        let mock = MockNetworkManager()
        let service = MonitorService(network: mock, cacheTTL: 30)

        _ = try await service.trafficInfoList()
        _ = try await service.trafficInfoList(forceRefresh: true)
        let callCount = await mock.callCount

        XCTAssertEqual(callCount, 2)
    }

    func testTrafficInfoListCoalescesConcurrentRequests() async throws {
        let mock = MockNetworkManager(delay: .milliseconds(50))
        let service = MonitorService(network: mock, cacheTTL: 0, minInterval: 0)

        async let first = service.trafficInfoList(forceRefresh: true)
        async let second = service.trafficInfoList(forceRefresh: true)
        _ = try await (first, second)

        let callCount = await mock.callCount
        XCTAssertEqual(callCount, 1)
    }

    func testTrafficInfoListFallsBackToStaleCache() async throws {
        let mock = MockNetworkManager()
        let service = MonitorService(network: mock, cacheTTL: 0, minInterval: 0)

        let current = try await service.trafficInfoSnapshot()
        await mock.setShouldFail(true)

        let stale = try await service.trafficInfoSnapshot(forceRefresh: true)
        XCTAssertTrue(stale.infos.isEmpty)
        XCTAssertTrue(stale.isStale)
        XCTAssertEqual(stale.updatedAt, current.updatedAt)
        let callCount = await mock.callCount
        XCTAssertEqual(callCount, 2)
    }

    func testMonitorServiceSpacesNetworkCallsWithInjectedScheduler() async throws {
        let scheduler = TestMonitorScheduler()
        let service = MonitorService(
            network: MockNetworkManager(),
            cacheTTL: 0,
            minInterval: 0.5,
            scheduler: scheduler
        )

        _ = try await service.monitor(diva: 1, forceRefresh: true)
        _ = try await service.monitor(diva: 2, forceRefresh: true)

        let sleeps = await scheduler.sleeps
        XCTAssertEqual(sleeps.count, 1)
        XCTAssertEqual(sleeps.first ?? .nan, 0.5, accuracy: 0.000_001)
    }

    func testMonitorServiceUsesBoundedExponentialRateLimitBackoff() async throws {
        let scheduler = TestMonitorScheduler()
        let network = RateLimitedNetworkManager(failuresBeforeSuccess: 2)
        let service = MonitorService(
            network: network,
            cacheTTL: 0,
            minInterval: 0,
            maxRetries: 2,
            scheduler: scheduler
        )

        _ = try await service.monitor(diva: 1, forceRefresh: true)

        let sleeps = await scheduler.sleeps
        let callCount = await network.callCount
        XCTAssertEqual(sleeps.count, 2)
        XCTAssertEqual(sleeps.first ?? .nan, 0.8, accuracy: 0.000_001)
        XCTAssertEqual(sleeps.last ?? .nan, 1.6, accuracy: 0.000_001)
        XCTAssertEqual(callCount, 3)
    }

    func testTrafficInfoDecodesFeedCategory() throws {
        let json = """
        {
          "data": {
            "monitors": [],
            "trafficInfos": [{
              "refTrafficInfoCategoryId": 3,
              "name": "stop-change",
              "title": "Betrieb ab Hirschengasse",
              "description": "Haltestelle verlegt",
              "priority": "1",
              "relatedLines": ["57A"]
            }]
          }
        }
        """

        let response = try JSONDecoder().decode(MonitorResponse.self, from: Data(json.utf8))

        XCTAssertEqual(response.data.trafficInfos?.first?.categoryID, 3)
    }

    // MARK: - LineColors

    func testLineColorsU1() {
        let color = LineColors.color(for: "U1")
        XCTAssertNotNil(color)
    }

    func testLineCategoryOfU1() {
        XCTAssertEqual(LineCategory.of("U1"), .metro)
    }

    func testLineCategoryOfS1() {
        XCTAssertEqual(LineCategory.of("S1"), .sbahn)
    }

    func testLineCategoryOf13A() {
        XCTAssertEqual(LineCategory.of("13A"), .bus)
    }

    func testLineCategoryOfN25() {
        XCTAssertEqual(LineCategory.of("N25"), .night)
    }

    func testLineCategoryOfTram() {
        XCTAssertEqual(LineCategory.of("O"), .tram)
        XCTAssertEqual(LineCategory.of("D"), .tram)
    }

    // MARK: - WidgetDepartureData

    func testWidgetDepartureDataCodable() {
        let fetchedAt = Date(timeIntervalSince1970: 1_000)
        let dataUpdatedAt = fetchedAt.addingTimeInterval(-30)
        let data = WidgetDepartureData(
            diva: "60200195",
            lineName: "U1",
            stopName: "Stephansplatz",
            destination: "Leopoldau",
            departures: [2, 5, 12],
            fetchedAt: fetchedAt,
            dataUpdatedAt: dataUpdatedAt
        )
        let encoded = try! JSONEncoder().encode(data)
        let decoded = try! JSONDecoder().decode(WidgetDepartureData.self, from: encoded)
        XCTAssertEqual(decoded.lineName, "U1")
        XCTAssertEqual(decoded.diva, "60200195")
        XCTAssertEqual(decoded.departures, [2, 5, 12])
        XCTAssertEqual(decoded.fetchedAt, fetchedAt)
        XCTAssertEqual(decoded.dataUpdatedAt, dataUpdatedAt)
    }

    func testWidgetDepartureDataDecodesLegacyPayload() throws {
        let legacy = """
        {
          "lineName": "U1",
          "stopName": "Stephansplatz",
          "destination": "Leopoldau",
          "departures": [2, 5, 12]
        }
        """

        let decoded = try JSONDecoder().decode(
            WidgetDepartureData.self,
            from: Data(legacy.utf8)
        )

        XCTAssertNil(decoded.diva)
        XCTAssertNil(decoded.fetchedAt)
        XCTAssertNil(decoded.dataUpdatedAt)
        XCTAssertEqual(decoded.departures, [2, 5, 12])
    }

    func testLegacyWidgetDecoderIgnoresNewSourceFreshnessField() throws {
        struct LegacyWidgetDepartureData: Decodable {
            let lineName: String
            let stopName: String
            let destination: String
            let departures: [Int]
            let fetchedAt: Date?
        }

        let projectionAnchor = Date(timeIntervalSince1970: 2_000)
        let encoded = try JSONEncoder().encode(
            WidgetDepartureData(
                lineName: "U1",
                stopName: "Stephansplatz",
                destination: "Leopoldau",
                departures: [2, 5, 12],
                fetchedAt: projectionAnchor,
                dataUpdatedAt: projectionAnchor.addingTimeInterval(-300)
            )
        )
        let decoded = try JSONDecoder().decode(
            LegacyWidgetDepartureData.self,
            from: encoded
        )

        XCTAssertEqual(decoded.lineName, "U1")
        XCTAssertEqual(decoded.stopName, "Stephansplatz")
        XCTAssertEqual(decoded.destination, "Leopoldau")
        XCTAssertEqual(decoded.departures, [2, 5, 12])
        XCTAssertEqual(decoded.fetchedAt, projectionAnchor)
    }

    func testWidgetCountdownProjectionUsesEachRowsFetchTime() {
        let now = Date(timeIntervalSince1970: 10_000)
        let sourceUpdatedAt = now.addingTimeInterval(-300)
        let items = [
            WidgetDepartureData(
                lineName: "U1",
                stopName: "Stephansplatz",
                destination: "Leopoldau",
                departures: [1, 4, 8],
                fetchedAt: now.addingTimeInterval(-120),
                dataUpdatedAt: sourceUpdatedAt
            ),
            WidgetDepartureData(
                lineName: "U4",
                stopName: "Schwedenplatz",
                destination: "Heiligenstadt",
                departures: [2, 7],
                fetchedAt: now.addingTimeInterval(-60)
            ),
        ]

        let projected = WidgetCountdownProjection.items(
            items,
            fallbackUpdatedAt: nil,
            at: now
        )

        XCTAssertEqual(projected[0].departures, [2, 6])
        XCTAssertEqual(projected[1].departures, [1, 6])
        XCTAssertEqual(projected[0].dataUpdatedAt, sourceUpdatedAt)
    }

    func testWidgetFreshnessClampsFutureSourceDateAndUsesWholeMinutes() {
        let entryDate = Date(timeIntervalSince1970: 1_000)

        XCTAssertEqual(
            WidgetFreshness.elapsedWholeMinutes(
                since: entryDate.addingTimeInterval(1),
                at: entryDate
            ),
            0
        )
        XCTAssertEqual(
            WidgetFreshness.elapsedWholeMinutes(
                since: entryDate.addingTimeInterval(-179),
                at: entryDate
            ),
            2
        )
    }

    func testWidgetFreshnessDoesNotTreatProjectionAnchorAsSourceRefresh() {
        let sourceUpdatedAt = Date(timeIntervalSince1970: 1_000)
        let projectionAnchor = sourceUpdatedAt.addingTimeInterval(300)
        let item = WidgetDepartureData(
            lineName: "U1",
            stopName: "Stephansplatz",
            destination: "Leopoldau",
            departures: [2, 7],
            fetchedAt: projectionAnchor,
            dataUpdatedAt: sourceUpdatedAt
        )

        XCTAssertEqual(
            WidgetFreshness.displayedUpdatedAt(
                items: [item],
                fallback: sourceUpdatedAt
            ),
            sourceUpdatedAt
        )
    }

    func testWidgetFreshnessUsesOldestSourceAcrossVisibleRows() {
        let projectionAnchor = Date(timeIntervalSince1970: 2_000)
        let oldestUpdate = projectionAnchor.addingTimeInterval(-300)
        let newerUpdate = projectionAnchor.addingTimeInterval(-60)
        let items = [
            WidgetDepartureData(
                lineName: "U1",
                stopName: "Stephansplatz",
                destination: "Leopoldau",
                departures: [2],
                fetchedAt: projectionAnchor,
                dataUpdatedAt: newerUpdate
            ),
            WidgetDepartureData(
                lineName: "U4",
                stopName: "Schwedenplatz",
                destination: "Heiligenstadt",
                departures: [3],
                fetchedAt: projectionAnchor,
                dataUpdatedAt: oldestUpdate
            ),
        ]

        XCTAssertEqual(
            WidgetFreshness.displayedUpdatedAt(
                items: items,
                fallback: nil
            ),
            oldestUpdate
        )
    }

    func testWidgetSyncPersistsOldestSourceFreshness() throws {
        let suiteName = "TrafficViennaTests.WidgetSync.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let projectionAnchor = Date(timeIntervalSince1970: 2_000)
        let oldestUpdate = projectionAnchor.addingTimeInterval(-300)
        let manager = WidgetSyncManager(
            appGroupID: suiteName,
            widgetKind: "TrafficViennaTests"
        )
        manager.save([
            WidgetDepartureData(
                lineName: "U1",
                stopName: "Stephansplatz",
                destination: "Leopoldau",
                departures: [2],
                fetchedAt: projectionAnchor,
                dataUpdatedAt: oldestUpdate
            ),
        ])

        XCTAssertEqual(
            defaults.object(forKey: "widget_last_updated") as? Date,
            oldestUpdate
        )
        let encoded = try XCTUnwrap(defaults.data(forKey: "widget_departure"))
        let decoded = try JSONDecoder().decode(
            [WidgetDepartureData].self,
            from: encoded
        )
        XCTAssertEqual(decoded.first?.fetchedAt, projectionAnchor)
        XCTAssertEqual(decoded.first?.dataUpdatedAt, oldestUpdate)
    }

    func testWidgetSnapshotUsesPlaceholderForEmptyGalleryPreview() {
        XCTAssertEqual(
            WidgetSnapshotPolicy.content(
                hasItems: false,
                isPreview: true
            ),
            .placeholder
        )
    }

    func testWidgetSnapshotUsesEmptyStateForEmptyRuntimeSnapshot() {
        XCTAssertEqual(
            WidgetSnapshotPolicy.content(
                hasItems: false,
                isPreview: false
            ),
            .empty
        )
    }

    func testWidgetSnapshotPrefersRealItemsInPreviewAndRuntime() {
        XCTAssertEqual(
            WidgetSnapshotPolicy.content(
                hasItems: true,
                isPreview: true
            ),
            .items
        )
        XCTAssertEqual(
            WidgetSnapshotPolicy.content(
                hasItems: true,
                isPreview: false
            ),
            .items
        )
    }

    func testWidgetTimelineScheduleIncludesVisibleDepartureBoundaries() {
        let now = Date(timeIntervalSince1970: 10_000)
        let refreshDate = now.addingTimeInterval(300)
        let items = [
            WidgetDepartureData(
                lineName: "U1",
                stopName: "Stephansplatz",
                destination: "Leopoldau",
                departures: [1, 3, 8],
                fetchedAt: now
            ),
            WidgetDepartureData(
                lineName: "U4",
                stopName: "Schwedenplatz",
                destination: "Heiligenstadt",
                departures: [2, 7],
                fetchedAt: now
            ),
        ]

        let dates = WidgetTimelineSchedule.entryDates(
            now: now,
            refreshDate: refreshDate,
            items: items,
            fallbackUpdatedAt: nil
        )

        XCTAssertEqual(
            dates,
            [
                now,
                now.addingTimeInterval(60),
                now.addingTimeInterval(120),
                now.addingTimeInterval(180),
                now.addingTimeInterval(240),
                refreshDate,
            ]
        )
    }

    func testWidgetTimelineScheduleRemovesThirdVisibleDepartureBeforeRefresh() {
        let now = Date(timeIntervalSince1970: 10_000)
        let refreshDate = now.addingTimeInterval(300)
        let items = [
            WidgetDepartureData(
                lineName: "U1",
                stopName: "Stephansplatz",
                destination: "Leopoldau",
                departures: [1, 2, 3],
                fetchedAt: now
            ),
        ]

        let dates = WidgetTimelineSchedule.entryDates(
            now: now,
            refreshDate: refreshDate,
            items: items,
            fallbackUpdatedAt: nil
        )

        XCTAssertEqual(
            dates,
            [
                now,
                now.addingTimeInterval(60),
                now.addingTimeInterval(120),
                now.addingTimeInterval(180),
                now.addingTimeInterval(240),
                refreshDate,
            ]
        )
    }

    func testWidgetRefreshThrottleScopesRecentAttemptsToSelectedRoutes() {
        let now = Date(timeIntervalSince1970: 10_000)
        let u1 = FavoriteRoute(
            diva: "60200123",
            lineName: "U1",
            destination: "Leopoldau"
        )
        let u4 = FavoriteRoute(
            diva: "60200644",
            lineName: "U4",
            destination: "Heiligenstadt"
        )
        let u1Key = WidgetRefreshThrottle.attemptKey(
            baseKey: "widget_last_fetch_attempt",
            routes: [u1]
        )
        let u4Key = WidgetRefreshThrottle.attemptKey(
            baseKey: "widget_last_fetch_attempt",
            routes: [u4]
        )

        XCTAssertNotEqual(u1Key, u4Key)
        XCTAssertFalse(
            WidgetRefreshThrottle.shouldFetch(
                routes: [u1],
                lastAttempt: now.addingTimeInterval(-60),
                refreshRequestedAt: nil,
                now: now
            )
        )
        XCTAssertTrue(
            WidgetRefreshThrottle.shouldFetch(
                routes: [u4],
                lastAttempt: nil,
                refreshRequestedAt: nil,
                now: now
            )
        )
    }

    func testWidgetRefreshThrottleSharesScopeAcrossRouteOrdering() {
        let u1 = FavoriteRoute(
            diva: "60200123",
            lineName: "U1",
            destination: "Leopoldau"
        )
        let u4 = FavoriteRoute(
            diva: "60200644",
            lineName: "U4",
            destination: "Heiligenstadt"
        )

        XCTAssertEqual(
            WidgetRefreshThrottle.attemptKey(
                baseKey: "widget_last_fetch_attempt",
                routes: [u1, u4]
            ),
            WidgetRefreshThrottle.attemptKey(
                baseKey: "widget_last_fetch_attempt",
                routes: [u4, u1, u4]
            )
        )
    }

    func testWidgetRefreshThrottleSkipsEmptySelectionsAndHonoursManualRefresh() {
        let now = Date(timeIntervalSince1970: 10_000)
        let route = FavoriteRoute(
            diva: "60200123",
            lineName: "U1",
            destination: "Leopoldau"
        )

        XCTAssertFalse(
            WidgetRefreshThrottle.shouldFetch(
                routes: [],
                lastAttempt: nil,
                refreshRequestedAt: now,
                now: now
            )
        )
        XCTAssertTrue(
            WidgetRefreshThrottle.shouldFetch(
                routes: [route],
                lastAttempt: now.addingTimeInterval(-60),
                refreshRequestedAt: now,
                now: now
            )
        )
    }

    func testWidgetDataMergePreservesSelectedOrderAndCachedFailures() {
        let selected = [
            WidgetRouteKey(lineName: "U4", destination: "Heiligenstadt"),
            WidgetRouteKey(lineName: "U1", destination: "Leopoldau"),
        ]
        let cached = [
            WidgetDepartureData(
                lineName: "U4",
                stopName: "Karlsplatz",
                destination: "Heiligenstadt",
                departures: [5]
            ),
        ]
        let fresh = [
            WidgetDepartureData(
                lineName: "U1",
                stopName: "Stephansplatz",
                destination: "Leopoldau",
                departures: [2]
            ),
        ]

        let merged = WidgetDataMerge.ordered(
            selected: selected,
            fresh: fresh,
            cached: cached
        )

        XCTAssertEqual(merged.map(\.lineName), ["U4", "U1"])
        XCTAssertEqual(merged.map(\.departures), [[5], [2]])
    }

    func testWidgetDataMergeKeepsSameRouteAtDifferentStopsDistinct() {
        let selected = [
            WidgetRouteKey(diva: "1", lineName: "U1", destination: "Leopoldau"),
            WidgetRouteKey(diva: "2", lineName: "U1", destination: "Leopoldau"),
        ]
        let fresh = [
            WidgetDepartureData(
                diva: "1",
                lineName: "U1",
                stopName: "Karlsplatz",
                destination: "Leopoldau",
                departures: [2]
            ),
            WidgetDepartureData(
                diva: "2",
                lineName: "U1",
                stopName: "Stephansplatz",
                destination: "Leopoldau",
                departures: [4]
            ),
        ]

        let merged = WidgetDataMerge.ordered(
            selected: selected,
            fresh: fresh,
            cached: []
        )

        XCTAssertEqual(merged.map(\.stopName), ["Karlsplatz", "Stephansplatz"])
        XCTAssertEqual(merged.map(\.departures), [[2], [4]])
    }

    func testFavoriteRouteOrderIsSharedAndDeterministic() {
        let routes = [
            FavoriteRoute(diva: "2", lineName: "U4", destination: "Heiligenstadt"),
            FavoriteRoute(diva: "1", lineName: "U1", destination: "Leopoldau"),
        ]

        XCTAssertEqual(routes.sorted().map(\.lineName), ["U1", "U4"])
    }

    func testFavoriteRouteStableIDIsDeterministicAndCollisionSafe() {
        let route = FavoriteRoute(
            diva: "60200123",
            lineName: "U1",
            destination: "Leopoldau"
        )
        let differentRoute = FavoriteRoute(
            diva: "60200123",
            lineName: "U1",
            destination: "Oberlaa"
        )

        XCTAssertEqual(route.stableID, route.stableID)
        XCTAssertNotEqual(route.stableID, differentRoute.stableID)
    }
}

// MARK: - Mock Network Manager

private actor MockNetworkManager: NetworkManaging {
    private(set) var callCount = 0
    private var shouldFail = false
    private let delay: Duration

    init(shouldFail: Bool = false, delay: Duration = .zero) {
        self.shouldFail = shouldFail
        self.delay = delay
    }

    func setShouldFail(_ shouldFail: Bool) {
        self.shouldFail = shouldFail
    }

    func fetchMonitorData(diva: Int, includeArea: Bool) async throws -> MonitorResponse {
        callCount += 1
        try await waitIfNeeded()
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return mockResponse()
    }

    func fetchTrafficInfoList() async throws -> MonitorResponse {
        callCount += 1
        try await waitIfNeeded()
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return mockResponse()
    }

    private func waitIfNeeded() async throws {
        guard delay != .zero else { return }
        try await Task.sleep(for: delay)
    }

    private func mockResponse() -> MonitorResponse {
        let departure = Departure(departureTime: DepartureTime(countdown: 5, timePlanned: nil, timeReal: nil))
        let departures = Departures(departure: [departure])
        let line = Lines(name: "U1", towards: "Leopoldau", departures: departures)
        let attr = Attributes(rbl: 1234)
        let props = Properties(title: "Test Stop", attributes: attr)
        let stop = LocationStop(properties: props, geometry: nil)
        let monitor = Monitor(locationStop: stop, lines: [line])
        let data = DataBlock(monitors: [monitor], trafficInfos: nil)
        return MonitorResponse(data: data)
    }
}

private actor TestMonitorScheduler: MonitorScheduling {
    private var current = Date(timeIntervalSince1970: 1_700_000_000)
    private(set) var sleeps: [TimeInterval] = []

    func now() async -> Date {
        current
    }

    func sleep(for duration: Duration) async throws {
        try Task.checkCancellation()
        let components = duration.components
        let interval = Double(components.seconds)
            + Double(components.attoseconds) / 1_000_000_000_000_000_000
        sleeps.append(interval)
        current = current.addingTimeInterval(interval)
    }
}

private actor RateLimitedNetworkManager: NetworkManaging {
    private var failuresRemaining: Int
    private(set) var callCount = 0

    init(failuresBeforeSuccess: Int) {
        failuresRemaining = failuresBeforeSuccess
    }

    func fetchMonitorData(diva: Int, includeArea: Bool) async throws -> MonitorResponse {
        try response()
    }

    func fetchTrafficInfoList() async throws -> MonitorResponse {
        try response()
    }

    private func response() throws -> MonitorResponse {
        callCount += 1
        if failuresRemaining > 0 {
            failuresRemaining -= 1
            throw MonitorApiError.rateLimited
        }
        return MonitorResponse(data: DataBlock(monitors: [], trafficInfos: []))
    }
}
