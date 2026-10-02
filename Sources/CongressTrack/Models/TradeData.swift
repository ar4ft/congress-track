import Foundation

enum TradeData {
    static func decode(_ data: Data) throws -> [Trade] {
        try JSONDecoder().decode([Trade].self, from: data)
    }
    static func merge(_ existing: [Trade], _ incoming: [Trade]) -> [Trade] {
        var byID = Dictionary(existing.map { ($0.id, $0) }, uniquingKeysWith: { _, newer in newer })
        for trade in incoming {
            if let existing = byID[trade.id], existing.provenance.retrievedAt > trade.provenance.retrievedAt { continue }
            byID[trade.id] = trade
        }
        return byID.values.sorted {
            $0.filedAt == $1.filedAt ? $0.id < $1.id : $0.filedAt > $1.filedAt
        }
    }
}
