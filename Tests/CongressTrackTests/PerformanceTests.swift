import XCTest
@testable import CongressTrack

final class PerformanceTests: XCTestCase {
    private func trade(_ id: String = "one", ticker: String? = "TEST", filed: String = "2026-01-02", type: String = "stock", side: String = "buy", member: String = "Member", amount: Int = 1001) -> Trade {
        Trade(id: id, chamber: "house", member: .init(name: member, bioguideId: member, party: "Democrat", state: "CA"),
              filedAt: filed, transactedAt: "2025-12-20", ticker: ticker, assetDescription: "Test asset", assetType: type,
              side: side, amountRange: .init(min: Double(amount), max: Double(amount * 2), text: "Range"), owner: "spouse",
              provenance: .init(source: "test", sourceUrl: "https://example.com/filing", retrievedAt: "2026-01-03T00:00:00Z", needsReview: false))
    }
    private var prices: PriceArchive {
        // Friday filing, next Monday entry: the large filing-day movement must be ignored.
        PriceArchive(series: [
            "TEST": [.init(date: "2026-01-02", close: 10), .init(date: "2026-01-05", close: 100),
                     .init(date: "2026-01-06", close: 105), .init(date: "2026-01-07", close: 110)],
            "SPY": [.init(date: "2026-01-02", close: 10), .init(date: "2026-01-05", close: 200),
                    .init(date: "2026-01-06", close: 202), .init(date: "2026-01-07", close: 204)]
        ])
    }
    private var asOf: Date { Day.parse("2026-01-10")! }

    func testNoLookAheadAndMatchedBenchmark() throws {
        let report = PerformanceEngine.evaluate(trades: [trade()], prices: prices, window: 2, asOf: asOf)
        let leader = try XCTUnwrap(report.leaders.first)
        XCTAssertEqual(leader.events.first?.entry, "2026-01-05")
        XCTAssertEqual(leader.events.first?.exit, "2026-01-07")
        XCTAssertEqual(leader.returnPct, 10, accuracy: 0.000001)
        XCTAssertEqual(leader.benchmarkPct, 2, accuracy: 0.000001)
        XCTAssertEqual(leader.excessPct, 8, accuracy: 0.000001)
        XCTAssertEqual(leader.curve.first?.model, 100)
        XCTAssertEqual(try XCTUnwrap(leader.curve.last?.model), 110, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(leader.curve.last?.benchmark), 102, accuracy: 0.000001)
    }

    func testAmountsNeverBecomeWeights() throws {
        var archive = prices
        archive.series["OTHER"] = [.init(date: "2026-01-05", close: 100), .init(date: "2026-01-06", close: 95), .init(date: "2026-01-07", close: 90)]
        let report = PerformanceEngine.evaluate(trades: [trade(amount: 1001), trade("two", ticker: "OTHER", amount: 1_000_000)], prices: archive, window: 2, asOf: asOf)
        let leader = try XCTUnwrap(report.leaders.first)
        XCTAssertEqual(leader.events.count, 2)
        XCTAssertEqual(leader.returnPct, 0, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(leader.curve.last?.model), 100, accuracy: 0.000001)
    }

    func testIncompletePeriodsAndUnsupportedAssetsAreReported() {
        let trades = [trade(), trade("option", type: "option"), trade("missing", ticker: nil), trade("sale", side: "sell")]
        let report = PerformanceEngine.evaluate(trades: trades, prices: prices, window: 30, asOf: asOf)
        XCTAssertTrue(report.leaders.isEmpty)
        XCTAssertEqual(report.candidateCount, 3)
        XCTAssertEqual(report.skipped.count, 3)
        XCTAssertTrue(report.skipped.contains { $0.reason == "Holding period not complete" })
    }

    func testMissingBenchmarkDoesNotProduceAPhantomRanking() {
        var archive = prices; archive.series["SPY"] = []
        let report = PerformanceEngine.evaluate(trades: [trade()], prices: archive, window: 2, asOf: asOf)
        XCTAssertEqual(report.scoredCount, 0)
        XCTAssertEqual(report.skipped.count, 1)
    }

    func testEntryAndExitUseCommonTradingDates() throws {
        var archive = prices
        archive.series["SPY"]?.removeAll { $0.date == "2026-01-05" }
        let report = PerformanceEngine.evaluate(trades: [trade()], prices: archive, window: 1, asOf: asOf)
        let event = try XCTUnwrap(report.leaders.first?.events.first)
        XCTAssertEqual(event.entry, "2026-01-06")
        XCTAssertEqual(event.exit, "2026-01-07")
        XCTAssertEqual(event.returnPct, (110.0 / 105 - 1) * 100, accuracy: 0.000001)
    }

    func testLongCoverageGapIsExcluded() {
        let archive = PriceArchive(series: [
            "TEST": [.init(date: "2026-01-05", close: 100), .init(date: "2026-02-05", close: 120)],
            "SPY": [.init(date: "2026-01-05", close: 200), .init(date: "2026-02-05", close: 210)]
        ])
        let report = PerformanceEngine.evaluate(trades: [trade()], prices: archive, window: 30, asOf: Day.parse("2026-02-10")!)
        XCTAssertTrue(report.leaders.isEmpty)
        XCTAssertTrue(report.skipped.first?.reason.contains("gap") == true)
    }

    func testRankingUsesModeledReturns() {
        var archive = prices
        archive.series["OTHER"] = [.init(date: "2026-01-05", close: 100), .init(date: "2026-01-06", close: 100), .init(date: "2026-01-07", close: 90)]
        let report = PerformanceEngine.evaluate(trades: [trade(member: "Winner"), trade("two", ticker: "OTHER", member: "Loser")], prices: archive, window: 2, asOf: asOf)
        XCTAssertEqual(report.leaders.map(\.member.name), ["Winner", "Loser"])
    }

    func testCSVRequiresBenchmarkAndRejectsInvalidData() throws {
        let valid = "date,ticker,adjusted_close\n2026-01-05,test,100\n2026-01-05,SPY,200\n"
        XCTAssertEqual(try PriceCSV.parse(valid)["TEST"]?.first?.close, 100)
        for bad in ["date,ticker,close\n2026-01-05,SPY,200", "date,ticker,adjusted_close\n2026-01-05,TEST,100",
                    "date,ticker,adjusted_close\n2026-02-30,SPY,100", "date,ticker,adjusted_close\n2026-01-05,SPY,nan",
                    "date,ticker,adjusted_close\n2026-01-05,SPY,100\n2026-01-05,SPY,200"] {
            XCTAssertThrowsError(try PriceCSV.parse(bad))
        }
    }

    func testAlertsIgnoreKnownRowsAndMatchMembersOrTickers() {
        let known = trade(), byTicker = trade("ticker"), byMember = trade("member", ticker: "OTHER", member: "Followed")
        let matches = AlertPolicy.newMatches(old: [known], new: [known, byTicker, byMember, trade("unwatched", ticker: "OTHER")], members: ["Followed"], tickers: ["TEST"])
        XCTAssertEqual(Set(matches.map(\.id)), ["ticker", "member"])
    }

    func testYearShardsExcludeDuplicateAggregate() throws {
        let json = #"{"lastIngestedAt":null,"stale":false,"rows":2,"snapshots":[{"file":"snapshot-2025.json.gz","rows":1},{"file":"snapshot-2026.json.gz","rows":1},{"file":"snapshot.json.gz","rows":2}]}"#
        let dataset = try JSONDecoder().decode(DataManifest.Dataset.self, from: Data(json.utf8))
        XCTAssertEqual(HistorySync.snapshots(dataset), ["snapshot-2025.json.gz", "snapshot-2026.json.gz"])
    }

    func testBundledSnapshotDecodes() throws {
        let rows = try TradeData.decode(Data(contentsOf: AppResources.url("trades", extension: "json")))
        XCTAssertEqual(rows.count, 175)
        XCTAssertEqual(Set(rows.map(\.id)).count, rows.count)
    }

    func testInvalidGzipFailsWithoutReplacingHistory() async {
        do {
            _ = try await HistorySync.decodeGzip(Data("invalid gzip".utf8))
            XCTFail("Invalid archive should fail")
        } catch { /* expected */ }
    }
}
