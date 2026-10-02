import Foundation

/// Serializes disk access away from the UI actor. Writes are atomic and precede publication.
actor LocalStorage {
    static let shared = LocalStorage()

    func read<T: Decodable & Sendable>(_ type: T.Type, from url: URL) throws -> T {
        try JSONDecoder().decode(type, from: Data(contentsOf: url))
    }

    func write<T: Encodable & Sendable>(_ value: T, to url: URL) throws {
        try Task.checkCancellation()
        let data = try JSONEncoder().encode(value)
        try Task.checkCancellation()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }

    func importPrices(from url: URL) throws -> PriceArchive {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        let parsed = try PriceCSV.parse(String(contentsOf: url, encoding: .utf8))
        try Task.checkCancellation()
        return PriceArchive(series: parsed,
                            sources: Dictionary(uniqueKeysWithValues: parsed.keys.map { ($0, "Imported adjusted-close CSV") }),
                            updatedAt: Date())
    }
}
