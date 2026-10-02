import Foundation
import Observation

@MainActor
@Observable
final class LeaderboardModel {
    var window = 30
    var minimumSamples = 1 { didSet { updateRanking() } }
    var rankByExcess = false { didSet { updateRanking() } }
    var selectedID: String?
    private(set) var report = PerformanceReport(leaders: [], skipped: [], scoredCount: 0, candidateCount: 0)
    private(set) var leaders: [LeaderboardEntry] = []
    private(set) var calculating = false
    var selected: LeaderboardEntry? { leaders.first { $0.id == selectedID } ?? leaders.first }

    func calculate(trades: [Trade], prices: PriceArchive) async {
        calculating = true
        do {
            let updated = try await PerformanceEngine.evaluateAsync(trades: trades, prices: prices, window: window)
            try Task.checkCancellation()
            report = updated; updateRanking(); calculating = false
        } catch { /* The task for the next request replaces this calculation. */ }
    }
    private func updateRanking() {
        let eligible = report.leaders.filter { $0.events.count >= minimumSamples }
        leaders = rankByExcess ? eligible.sorted {
            $0.excessPct == $1.excessPct ? $0.member.name < $1.member.name : $0.excessPct > $1.excessPct
        } : eligible
    }
}
