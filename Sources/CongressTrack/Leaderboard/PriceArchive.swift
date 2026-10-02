import Foundation

struct PriceArchive: Codable, Sendable {
    var series: [String: [PriceBar]] = [:]
    var sources: [String: String] = [:]
    var updatedAt: Date?
}
