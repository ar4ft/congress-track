import Foundation

enum PerformanceEngine {
    @concurrent
    static func evaluateAsync(trades: [Trade], prices: PriceArchive, window: Int) async throws -> PerformanceReport {
        try Task.checkCancellation()
        let result = evaluate(trades: trades, prices: prices, window: window)
        try Task.checkCancellation()
        return result
    }

    static func evaluate(trades: [Trade], prices: PriceArchive, window: Int, asOf: Date = Date()) -> PerformanceReport {
        var scored: [PricedEvent] = []
        var skipped: [SkippedEvent] = []
        let indexed = prices.series.mapValues { barsByDate($0, asOf: asOf) }
        let benchmark = indexed["SPY"] ?? [:]
        let candidates = trades.filter { $0.side == "buy" }
        for trade in candidates {
            if Task.isCancelled { break }
            func skip(_ reason: String) { skipped.append(SkippedEvent(trade: trade, reason: reason)) }
            guard window > 0 else { skip("Invalid holding period"); continue }
            guard trade.assetType == "stock", let ticker = trade.ticker, !ticker.isEmpty else {
                skip("No stock ticker; options, bonds, and unmapped assets are excluded"); continue
            }
            guard trade.provenance.needsReview != true else { skip("Source record needs review"); continue }
            guard let filing = Day.parse(trade.filedAt) else { skip("Invalid filing date"); continue }
            let stock = indexed[ticker.uppercased()] ?? [:]
            let common = Set(stock.keys).intersection(benchmark.keys).sorted()
            guard let entry = common.first(where: { $0 > trade.filedAt }), let entryDay = Day.parse(entry),
                  entryDay <= Day.adding(7, to: filing) else {
                skip("Missing stock or SPY close within 7 days after filing"); continue
            }
            let target = Day.adding(window, to: entryDay)
            guard target <= Day.calendar.startOfDay(for: asOf) else { skip("Holding period not complete"); continue }
            guard let exit = common.first(where: { $0 >= Day.string(target) }), let exitDay = Day.parse(exit),
                  exitDay <= Day.adding(7, to: target) else {
                skip("Missing stock or SPY exit close"); continue
            }
            let dates = common.filter { $0 >= entry && $0 <= exit }
            var prior = entryDay
            var hasGap = false
            for date in dates.dropFirst() {
                guard let next = Day.parse(date) else { hasGap = true; break }
                if next > Day.adding(7, to: prior) { hasGap = true; break }
                prior = next
            }
            guard !hasGap else { skip("Price gap exceeds 7 days during holding period"); continue }
            let initialStock = stock[entry]!
            let initialSPY = benchmark[entry]!
            let duration = exitDay.timeIntervalSince(entryDay)
            let curve = (0...20).map { index -> ReturnPoint in
                let date = Day.string(entryDay.addingTimeInterval(duration * Double(index) / 20))
                let observed = dates.last(where: { $0 <= date }) ?? entry
                return ReturnPoint(progress: index * 5,
                                   model: 100 * stock[observed]! / initialStock,
                                   benchmark: 100 * benchmark[observed]! / initialSPY)
            }
            scored.append(PricedEvent(trade: trade, entry: entry, exit: exit,
                                      returnPct: (stock[exit]! / initialStock - 1) * 100,
                                      benchmarkPct: (benchmark[exit]! / initialSPY - 1) * 100,
                                      curve: curve))
        }
        let groups = Dictionary(grouping: scored, by: { $0.trade.member.key })
        let excluded = Dictionary(grouping: skipped, by: { $0.trade.member.key })
        let leaders = groups.values.map { events in
            LeaderboardEntry(member: events[0].trade.member, events: events,
                             skipped: excluded[events[0].trade.member.key] ?? [])
        }.sorted {
            if abs($0.returnPct - $1.returnPct) > 0.000001 { return $0.returnPct > $1.returnPct }
            return $0.member.name < $1.member.name
        }
        return PerformanceReport(leaders: leaders, skipped: skipped, scoredCount: scored.count, candidateCount: candidates.count)
    }

    private static func barsByDate(_ bars: [PriceBar], asOf: Date) -> [String: Double] {
        let latest = Day.string(asOf)
        return Dictionary(bars.filter { $0.date <= latest && Day.parse($0.date) != nil && $0.close.isFinite && $0.close > 0 }
            .map { ($0.date, $0.close) }, uniquingKeysWith: { _, last in last })
    }
}
