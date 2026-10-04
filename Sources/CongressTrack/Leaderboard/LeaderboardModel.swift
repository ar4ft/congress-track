import Foundation
import Observation

@MainActor
@Observable
final class LeaderboardModel {
    var window = 30
    private(set) var analyzedWindow = 30
    var minimumSamples = 1 { didSet { updateRanking() } }
    var rankByExcess = false { didSet { updateRanking() } }
    var selectedID: String?
    private(set) var report = PerformanceReport(leaders: [], skipped: [], scoredCount: 0, candidateCount: 0)
    private(set) var leaders: [LeaderboardEntry] = []
    private(set) var rankedRows: [RankedLeader] = []
    private(set) var calculating = false
    var selected: LeaderboardEntry? { leaders.first { $0.id == selectedID } ?? leaders.first }

    func calculate(trades: [Trade], prices: PriceArchive) async {
        let requestedWindow = window
        calculating = true
        do {
            let updated = try await PerformanceEngine.evaluateAsync(trades: trades, prices: prices, window: requestedWindow)
            try Task.checkCancellation()
            report = updated; analyzedWindow = requestedWindow; updateRanking(); calculating = false
        } catch { /* The task for the next request replaces this calculation. */ }
    }
    private func updateRanking() {
        let eligible = report.leaders.filter { $0.events.count >= minimumSamples }
        leaders = rankByExcess ? eligible.sorted {
            $0.excessPct == $1.excessPct ? $0.member.name < $1.member.name : $0.excessPct > $1.excessPct
        } : eligible
        rankedRows = leaders.enumerated().map { RankedLeader(rank: $0.offset + 1, leader: $0.element) }
    }
}
