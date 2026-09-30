import Foundation

struct Trade: Codable, Identifiable, Hashable {
    struct Member: Codable, Hashable {
        let name: String
        let bioguideId: String?
        let party: String?
        let state: String?
        var key: String { bioguideId ?? name }
    }
    struct Amount: Codable, Hashable {
        let min: Double?
        let max: Double?
        let text: String
    }
    struct Provenance: Codable, Hashable {
        let source: String
        let sourceUrl: String
        let retrievedAt: String
        let needsReview: Bool?
    }
    let id: String
    let chamber: String
    let member: Member
    let filedAt: String
    let transactedAt: String
    let ticker: String?
    let assetDescription: String
    let assetType: String
    let side: String
    let amountRange: Amount
    let owner: String
    let provenance: Provenance

    var filingURL: URL? {
        guard let url = URL(string: provenance.sourceUrl), url.scheme == "https" else { return nil }
        return url
    }
    var delay: Int? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        guard let traded = formatter.date(from: transactedAt),
              let filed = formatter.date(from: filedAt) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.dateComponents([.day], from: traded, to: filed).day
    }
    func matches(_ query: String) -> Bool {
        query.isEmpty || [member.name, ticker ?? "", assetDescription, member.state ?? ""]
            .contains { $0.localizedCaseInsensitiveContains(query) }
    }
}

struct DataManifest: Decodable {
    struct Source: Decodable {
        let lastSyncOk: Bool?
        let lastSyncAt: String?
        let lastCanaryStatus: String?
        let lastCanaryAt: String?
    }
    struct Dataset: Decodable {
        struct Snapshot: Decodable { let file: String; let rows: Int }
        let lastIngestedAt: String?
        let stale: Bool?
        let snapshots: [Snapshot]?
        let rows: Int?
    }
    let generatedAt: String
    let datasets: [String: Dataset]
    let sources: [String: Source]?
}

enum AppResources {
    static func url(_ name: String, extension suffix: String) -> URL {
        Bundle.main.url(forResource: name, withExtension: suffix)
            ?? Bundle.module.url(forResource: name, withExtension: suffix)!
    }
}

enum Day {
    static var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }
    static func parse(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        guard let date = formatter.date(from: value), formatter.string(from: date) == value else { return nil }
        return date
    }
    static func string(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    static func adding(_ days: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: date)!
    }
}

enum TradeData {
    static func decode(_ data: Data) throws -> [Trade] {
        try JSONDecoder().decode([Trade].self, from: data)
    }
    static func merge(_ existing: [Trade], _ incoming: [Trade]) -> [Trade] {
        var byID = Dictionary(existing.map { ($0.id, $0) }, uniquingKeysWith: { _, newer in newer })
        for trade in incoming {
            if let existing = byID[trade.id], existing.provenance.retrievedAt > trade.provenance.retrievedAt { continue }
            byID[trade.id] = trade
        }
        return byID.values.sorted {
            $0.filedAt == $1.filedAt ? $0.id < $1.id : $0.filedAt > $1.filedAt
        }
    }
}
