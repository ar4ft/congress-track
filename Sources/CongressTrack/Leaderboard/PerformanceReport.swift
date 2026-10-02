import Foundation

struct PerformanceReport: Sendable {
    let leaders: [LeaderboardEntry]
    let skipped: [SkippedEvent]
    let scoredCount: Int
    let candidateCount: Int
}
