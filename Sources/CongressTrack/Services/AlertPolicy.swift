import Foundation

enum AlertPolicy {
    static func newMatches(old: [Trade], new: [Trade], members: Set<String>, tickers: Set<String>) -> [Trade] {
        let known = Set(old.map(\.id))
        return new.filter {
            !known.contains($0.id) &&
            (members.contains($0.member.key) || $0.ticker.map { tickers.contains($0.uppercased()) } == true)
        }
    }
}
