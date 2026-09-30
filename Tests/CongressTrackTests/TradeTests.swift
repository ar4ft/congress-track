import XCTest
@testable import CongressTrack

final class TradeTests: XCTestCase {
    private func record(id: String = "filing:1", ticker: String? = nil) throws -> Trade {
        let json: [String: Any] = [
            "id": id, "chamber": "house",
            "member": ["name": "Example Member", "bioguideId": "X000001", "party": "Democrat", "state": "CA"],
            "filedAt": "2026-02-03", "transactedAt": "2026-01-30",
            "ticker": ticker as Any? ?? NSNull(), "assetDescription": "Example asset", "assetType": "stock",
            "side": "buy", "amountRange": ["min": 1001, "max": 15000, "text": "$1,001 - $15,000"],
            "owner": "spouse", "provenance": ["source": "house-clerk", "sourceUrl": "https://disclosures-clerk.house.gov/example",
                "retrievedAt": "2026-02-04T00:00:00Z", "needsReview": false]
        ]
        return try JSONDecoder().decode(Trade.self, from: JSONSerialization.data(withJSONObject: json))
    }

    func testNullableTickerAndDisclosureDelay() throws {
        let trade = try record()
        XCTAssertNil(trade.ticker)
        XCTAssertEqual(trade.delay, 4)
        XCTAssertEqual(trade.owner, "spouse")
        XCTAssertEqual(trade.amountRange.text, "$1,001 - $15,000")
    }

    func testRefreshReplacesSameRecordWithoutDuplicating() throws {
        let initial = try record()
        let updated = try record(ticker: "TEST")
        let merged = TradeData.merge([initial], [updated, updated])
        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged.first?.ticker, "TEST")
    }

    func testSearchMatchesMemberTickerAssetAndState() throws {
        let trade = try record(ticker: "TEST")
        for query in ["member", "test", "asset", "ca", ""] { XCTAssertTrue(trade.matches(query)) }
        XCTAssertFalse(trade.matches("not present"))
    }
}
