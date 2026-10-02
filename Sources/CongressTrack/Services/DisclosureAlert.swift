import Foundation

struct DisclosureAlert: Codable, Identifiable, Sendable {
    let id: String
    let member: String
    let asset: String
    let filedAt: String
    let detectedAt: Date
}
