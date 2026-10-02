import Foundation

struct SkippedEvent: Identifiable, Sendable {
    var id: String { trade.id }
    let trade: Trade
    let reason: String
}
