import Foundation

struct SavedSearch: Codable, Identifiable, Sendable {
    var id = UUID()
    let name: String
    let query: String
    let chamber: String
    let side: String
    let party: String
    let memberKey: String?
    let since: String?
    let until: String?
    let ticker: String?
}
