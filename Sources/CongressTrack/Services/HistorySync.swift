import Foundation

enum HistorySync {
    static func snapshots(_ dataset: DataManifest.Dataset) -> [String] {
        let files = dataset.snapshots?.map(\.file) ?? []
        // Prefer disjoint year shards to avoid downloading the aggregate again.
        let years = files.filter { $0.range(of: #"^snapshot-\d{4}\.json\.gz$"#, options: .regularExpression) != nil }
        return years.isEmpty ? files.filter { $0 == "snapshot.json.gz" } : years.sorted()
    }

    @concurrent
    static func decodeGzip(_ data: Data) async throws -> [Trade] {
        try Task.checkCancellation()
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
        let rows = try TradeData.decode(decoded)
        try Task.checkCancellation()
        return rows
    }
}
