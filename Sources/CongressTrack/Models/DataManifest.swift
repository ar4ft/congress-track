import Foundation

struct DataManifest: Codable, Sendable {
    struct Source: Codable, Sendable {
        let lastSyncOk: Bool?
        let lastSyncAt: String?
        let lastCanaryStatus: String?
        let lastCanaryAt: String?
    }
    struct Dataset: Codable, Sendable {
        struct Snapshot: Codable, Sendable { let file: String; let rows: Int }
        let lastIngestedAt: String?
        let stale: Bool?
        let snapshots: [Snapshot]?
        let rows: Int?
    }
    let generatedAt: String
    let datasets: [String: Dataset]
    let sources: [String: Source]?
}
