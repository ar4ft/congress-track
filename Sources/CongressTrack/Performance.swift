import Foundation

struct PriceBar: Codable, Hashable {
    let date: String
    let close: Double
}

struct PriceArchive: Codable {
    var series: [String: [PriceBar]] = [:]
    var sources: [String: String] = [:]
    var updatedAt: Date?
}

struct ReturnPoint: Identifiable {
    var id: Int { progress }
    let progress: Int
    let model: Double
    let benchmark: Double
}

struct PricedEvent: Identifiable {
    var id: String { trade.id }
    let trade: Trade
    let entry: String
    let exit: String
    let returnPct: Double
    let benchmarkPct: Double
    let curve: [ReturnPoint]
}

struct SkippedEvent: Identifiable {
    var id: String { trade.id }
    let trade: Trade
    let reason: String
}

struct LeaderboardEntry: Identifiable {
    var id: String { member.key }
    let member: Trade.Member
    let events: [PricedEvent]
    let skipped: [SkippedEvent]
    var returnPct: Double { events.map(\.returnPct).reduce(0, +) / Double(events.count) }
    var benchmarkPct: Double { events.map(\.benchmarkPct).reduce(0, +) / Double(events.count) }
    var excessPct: Double { returnPct - benchmarkPct }
    var curve: [ReturnPoint] {
        (0...20).map { index in
            ReturnPoint(progress: index * 5,
                        model: events.map { $0.curve[index].model }.reduce(0, +) / Double(events.count),
                        benchmark: events.map { $0.curve[index].benchmark }.reduce(0, +) / Double(events.count))
        }
    }
}

struct PerformanceReport {
    let leaders: [LeaderboardEntry]
    let skipped: [SkippedEvent]
    let scoredCount: Int
    let candidateCount: Int
}

enum PerformanceEngine {
    static func evaluate(trades: [Trade], prices: PriceArchive, window: Int, asOf: Date = Date()) -> PerformanceReport {
        var scored: [PricedEvent] = []
        var skipped: [SkippedEvent] = []
        let indexed = prices.series.mapValues { barsByDate($0, asOf: asOf) }
        let benchmark = indexed["SPY"] ?? [:]
        let candidates = trades.filter { $0.side == "buy" }
        for trade in candidates {
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

enum PriceCSV {
    // A deliberate, strict CSV contract; no silent coercion of malformed rows.
    static func parse(_ text: String) throws -> [String: [PriceBar]] {
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard let header = lines.first,
              header.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "date,ticker,adjusted_close" else {
            throw PriceError.message("Expected CSV header: date,ticker,adjusted_close. Include SPY and use adjusted closes for every ticker.")
        }
        var result: [String: [PriceBar]] = [:]
        var keys = Set<String>()
        for (index, line) in lines.dropFirst().enumerated() {
            let fields = line.split(separator: ",", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
            guard fields.count == 3, Day.parse(fields[0]) != nil, !fields[1].isEmpty,
                  let value = Double(fields[2]), value.isFinite, value > 0 else {
                throw PriceError.message("Invalid price row \(index + 2). Expected a valid date, ticker, and positive adjusted close.")
            }
            let ticker = fields[1].uppercased()
            guard keys.insert(ticker + ":" + fields[0]).inserted else { throw PriceError.message("Duplicate ticker/date on row \(index + 2).") }
            result[ticker, default: []].append(PriceBar(date: fields[0], close: value))
        }
        guard !(result["SPY"] ?? []).isEmpty else { throw PriceError.message("The price file must include SPY benchmark prices.") }
        return result.mapValues { $0.sorted { $0.date < $1.date } }
    }
}

enum PriceError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case .message(let message) = self { return message }; return nil }
}
