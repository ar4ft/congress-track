import Foundation

struct LeaderboardEntry: Identifiable, Sendable {
    var id: String { member.key }
    let member: Trade.Member
    let events: [PricedEvent]
    let skipped: [SkippedEvent]
    let returnPct: Double
    let benchmarkPct: Double
    var excessPct: Double { returnPct - benchmarkPct }
    let curve: [ReturnPoint]

    init(member: Trade.Member, events: [PricedEvent], skipped: [SkippedEvent]) {
        self.member = member; self.events = events; self.skipped = skipped
        let count = Double(events.count)
        returnPct = events.isEmpty ? 0 : events.reduce(0) { $0 + $1.returnPct } / count
        benchmarkPct = events.isEmpty ? 0 : events.reduce(0) { $0 + $1.benchmarkPct } / count
        curve = events.isEmpty ? [] : (0...20).compactMap { index in
            let points = events.compactMap { $0.curve.indices.contains(index) ? $0.curve[index] : nil }
            guard points.count == events.count else { return nil }
            return ReturnPoint(progress: index * 5,
                               model: points.reduce(0) { $0 + $1.model } / count,
                               benchmark: points.reduce(0) { $0 + $1.benchmark } / count)
        }
    }

}
