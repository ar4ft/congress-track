import XCTest
@testable import CongressTrack

final class WorkspaceTests: XCTestCase {
    private func trade(_ id: String, member: String = "José", ticker: String = "TEST") -> Trade {
        Trade(id: id, chamber: "house", member: .init(name: member, bioguideId: member, party: "Democrat", state: "CA"),
              filedAt: "2026-01-05", transactedAt: "2026-01-02", ticker: ticker, assetDescription: "Test stock",
              assetType: "stock", side: "buy", amountRange: .init(min: 1, max: 2, text: "$1–$2"), owner: "self",
              provenance: .init(source: "test", sourceUrl: "https://example.com", retrievedAt: "2026-01-06T00:00:00Z", needsReview: false))
    }
    func testCalendarDateIsStrictAndUTC() throws {
        XCTAssertNil(Day.parse("2026-02-30"))
        XCTAssertNil(Day.parse("2026-1-05"))
        XCTAssertNil(Day.parse("2026-01-05T00:00:00Z"))
        let date = try XCTUnwrap(Day.parse("2026-01-05"))
        XCTAssertEqual(date.timeIntervalSince1970, 1_767_571_200)
        XCTAssertEqual(Day.string(date), "2026-01-05")
        XCTAssertTrue(Day.display("2026-01-05").contains("5"))
    }
    func testSearchFindsDiacritics() {
        XCTAssertTrue(trade("one").matches("jose"))
    }
    func testSourceTimestampKeepsUTCAndHandlesFractionalSeconds() {
        let plain = SourceTimestamp.display("2026-09-04T20:31:37Z")
        XCTAssertEqual(SourceTimestamp.display("2026-09-04T20:31:37.868Z"), plain)
        XCTAssertEqual(SourceTimestamp.display("2026-09-04T22:31:37+02:00"), plain)
        XCTAssertTrue(plain.hasSuffix(" UTC"))
        XCTAssertEqual(SourceTimestamp.display("Unknown"), "Unknown")
    }
    @MainActor
    func testReportRetainsItsHoldingPeriodUntilNewCalculationCompletes() async throws {
        let prices = PriceArchive(series: [
            "TEST": [.init(date: "2026-01-06", close: 100), .init(date: "2026-01-07", close: 105), .init(date: "2026-01-08", close: 110)],
            "SPY": [.init(date: "2026-01-06", close: 200), .init(date: "2026-01-07", close: 202), .init(date: "2026-01-08", close: 204)]
        ])
        let model = LeaderboardModel(); model.window = 2
        await model.calculate(trades: [trade("one")], prices: prices)
        XCTAssertEqual(try XCTUnwrap(model.selected).returnPct, 10, accuracy: 0.000001)
        model.window = 90
        XCTAssertEqual(model.analyzedWindow, 2, "An existing graph must retain the period that produced its returns")
        XCTAssertEqual(try XCTUnwrap(model.selected).returnPct, 10, accuracy: 0.000001)
        await model.calculate(trades: [trade("one")], prices: prices)
        XCTAssertEqual(model.analyzedWindow, 90)
        XCTAssertEqual(model.report.scoredCount, 0)
    }
    func testQueryCombinesWatchlistAndFilters() async throws {
        var filters = TradeFilters(); filters.ticker = "TEST"
        let query = TradeQuery(revision: 1, filters: filters, watchlistOnly: true, members: ["Followed"], tickers: [])
        let rows = try await query.evaluate([trade("one", member: "Followed"), trade("two"), trade("three", member: "Followed", ticker: "OTHER")])
        XCTAssertEqual(rows.map(\.id), ["one"])
    }
    @MainActor
    func testRoutesRestoreSavedSearchAndClearConflictingFilters() {
        let model = WorkspaceModel()
        var filters = TradeFilters(); filters.search = "NVDA"; filters.chamber = "senate"
        filters.useDates = true; filters.since = Day.parse("2026-01-01") ?? .distantPast
        filters.until = Day.parse("2026-01-31") ?? .distantFuture
        let saved = filters.saved(name: "January purchases")
        model.route = .savedSearch(saved.id); model.applyRoute(searches: [saved])
        XCTAssertEqual(model.filters.search, "NVDA")
        XCTAssertEqual(model.filters.chamber, "senate")
        XCTAssertEqual(Day.string(model.filters.since), "2026-01-01")
        model.route = .member("Followed"); model.applyRoute(searches: [saved])
        XCTAssertEqual(model.filters.memberKey, "Followed")
        XCTAssertEqual(model.filters.search, "")
        XCTAssertFalse(model.filters.useDates)
        model.route = .ticker("TEST"); model.applyRoute(searches: [saved])
        XCTAssertNil(model.filters.memberKey)
        XCTAssertEqual(model.filters.ticker, "TEST")
    }
    @MainActor
    func testClearFiltersResetsMemberRouteButKeepsWatchlistScope() {
        let model = WorkspaceModel()
        model.route = .member("Followed"); model.applyRoute(searches: [])
        model.clearFilters()
        XCTAssertEqual(model.route, .all)
        XCTAssertNil(model.filters.memberKey)
        model.route = .watchlist
        model.filters.search = "TEST"
        model.clearFilters()
        XCTAssertEqual(model.route, .watchlist)
        XCTAssertFalse(model.filters.isActive)
    }
    func testCanceledAnalysisDoesNotReturnAPartialReport() async {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await PerformanceEngine.evaluateAsync(trades: [], prices: PriceArchive(), window: 30)
        }
        do { _ = try await task.value; XCTFail("Canceled calculation must not publish") }
        catch is CancellationError { /* expected */ }
        catch { XCTFail("Unexpected error: \(error)") }
    }
    func testCanceledStorageWritePreservesPreviousArchive() async throws {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        let old = PriceArchive(series: ["SPY": [.init(date: "2026-01-05", close: 100)]])
        try await LocalStorage.shared.write(old, to: url)
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await LocalStorage.shared.write(PriceArchive(), to: url)
        }
        do { try await task.value; XCTFail("Canceled write must not replace archive") }
        catch is CancellationError { /* expected */ }
        let retained = try await LocalStorage.shared.read(PriceArchive.self, from: url)
        XCTAssertEqual(retained.series["SPY"]?.first?.close, 100)
    }
    @MainActor
    func testCanceledPriceRefreshPreservesArchiveAndRevision() async throws {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        let stamp = Date(timeIntervalSince1970: 1234)
        try await LocalStorage.shared.write(PriceArchive(series: ["SPY": [.init(date: "2026-01-05", close: 100)]], updatedAt: stamp), to: url)
        let prices = PriceStore(cache: url)
        await prices.loadIfNeeded()
        let revision = prices.revision
        let task = Task { @MainActor in
            withUnsafeCurrentTask { $0?.cancel() }
            await prices.refresh(for: [])
        }
        await task.value
        XCTAssertEqual(prices.archive.updatedAt, stamp)
        XCTAssertEqual(prices.revision, revision)
        XCTAssertNil(prices.error)
        XCTAssertFalse(prices.loading)
    }
}
