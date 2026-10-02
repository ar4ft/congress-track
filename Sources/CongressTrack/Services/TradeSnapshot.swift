import Foundation

struct TradeSnapshot: Codable, Sendable {
    let trades: [Trade]
    let manifest: DataManifest
}
