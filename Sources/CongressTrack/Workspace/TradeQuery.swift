import Foundation

struct TradeQuery: Hashable, Sendable {
    let revision: Int
    let filters: TradeFilters
    let watchlistOnly: Bool
    let members: Set<String>
    let tickers: Set<String>

    @concurrent
    func evaluate(_ trades: [Trade]) async throws -> [Trade] {
        try Task.checkCancellation()
        let result = trades.filter {
            filters.matches($0) && (!watchlistOnly || members.contains($0.member.key) ||
                $0.ticker.map { tickers.contains($0.uppercased()) } == true)
        }
        try Task.checkCancellation()
        return result
    }
}
