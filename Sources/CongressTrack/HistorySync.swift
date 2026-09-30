import Foundation

enum HistorySync {
    static func snapshots(_ dataset: DataManifest.Dataset) -> [String] {
        let files = dataset.snapshots?.map(\.file) ?? []
        // Prefer disjoint year shards to avoid downloading the aggregate again.
        let years = files.filter { $0.range(of: #"^snapshot-\d{4}\.json\.gz$"#, options: .regularExpression) != nil }
        return years.isEmpty ? files.filter { $0 == "snapshot.json.gz" } : years.sorted()
    }

    static func decodeGzip(_ data: Data) async throws -> [Trade] {
        try await Task.detached(priority: .utility) {
            let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json.gz")
            try data.write(to: file)
            defer { try? FileManager.default.removeItem(at: file) }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/gzip")
            process.arguments = ["-dc", file.path]
            let output = Pipe()
            process.standardOutput = output
            process.standardError = FileHandle.nullDevice
            try process.run()
            let decoded = output.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { throw CocoaError(.fileReadCorruptFile) }
            return try TradeData.decode(decoded)
        }.value
    }
}

struct SavedSearch: Codable, Identifiable {
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

struct DisclosureAlert: Codable, Identifiable {
    let id: String
    let member: String
    let asset: String
    let filedAt: String
    let detectedAt: Date
}

enum AlertPolicy {
    static func newMatches(old: [Trade], new: [Trade], members: Set<String>, tickers: Set<String>) -> [Trade] {
        let known = Set(old.map(\.id))
        return new.filter {
            !known.contains($0.id) &&
            (members.contains($0.member.key) || $0.ticker.map { tickers.contains($0.uppercased()) } == true)
        }
    }
}
