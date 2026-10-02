import Foundation

struct Trade: Codable, Identifiable, Hashable, Sendable {
    struct Member: Codable, Hashable, Sendable {
        let name: String
        let bioguideId: String?
        let party: String?
        let state: String?
        var key: String { bioguideId ?? name }
    }
    struct Amount: Codable, Hashable, Sendable {
        let min: Double?
        let max: Double?
        let text: String
    }
    struct Provenance: Codable, Hashable, Sendable {
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
        guard let traded = Day.parse(transactedAt), let filed = Day.parse(filedAt) else { return nil }
        return Day.calendar.dateComponents([.day], from: traded, to: filed).day
    }
    func matches(_ query: String) -> Bool {
        query.isEmpty || [member.name, ticker ?? "", assetDescription, member.state ?? ""]
            .contains { $0.localizedStandardContains(query) }
    }
}
