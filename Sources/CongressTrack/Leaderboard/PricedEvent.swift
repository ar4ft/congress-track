import Foundation

struct PricedEvent: Identifiable, Sendable {
    var id: String { trade.id }
    let trade: Trade
    let entry: String
    let exit: String
    let returnPct: Double
    let benchmarkPct: Double
    let curve: [ReturnPoint]
}
