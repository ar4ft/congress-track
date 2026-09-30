import Foundation
import SwiftUI

@MainActor
final class TradeStore: ObservableObject {
    @Published private(set) var trades: [Trade] = []
    @Published private(set) var refreshing = false
    @Published private(set) var manifest: DataManifest?
    @Published private(set) var checkedAt: Date?
    @Published var error: String?
    @Published private(set) var followed: Set<String>

    private let defaults: UserDefaults
    private let base = "https://raw.githubusercontent.com/LuxAlgo/market-trackers-data/main/"
    private let cacheDirectory: URL

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        followed = Set(defaults.stringArray(forKey: "followedMembers") ?? [])
        cacheDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CongressTrack", isDirectory: true)
        do {
            let seed = try Data(contentsOf: Bundle.module.url(forResource: "trades", withExtension: "json")!)
            trades = TradeData.merge([], try TradeData.decode(seed))
            if let cache = try? Data(contentsOf: cacheDirectory.appendingPathComponent("trades.json")),
               let rows = try? TradeData.decode(cache) { trades = TradeData.merge(trades, rows) }
            let manifestURL = cacheDirectory.appendingPathComponent("manifest.json")
            let data: Data
            if let cached = try? Data(contentsOf: manifestURL) { data = cached }
            else { data = try Data(contentsOf: Bundle.module.url(forResource: "manifest", withExtension: "json")!) }
            manifest = try JSONDecoder().decode(DataManifest.self, from: data)
        } catch { self.error = "Could not load saved disclosures: \(error.localizedDescription)" }
    }

    func toggleFollow(_ member: Trade.Member) {
        if followed.contains(member.key) { followed.remove(member.key) }
        else { followed.insert(member.key) }
        defaults.set(Array(followed).sorted(), forKey: "followedMembers")
    }

    func refresh() async {
        guard !refreshing else { return }
        refreshing = true
        error = nil
        defer { refreshing = false }
        do {
            async let rowsData = download("congress/trades/latest.json")
            async let manifestData = download("manifest.json")
            let (rows, metadata) = try await (rowsData, manifestData)
            let updated = TradeData.merge(trades, try TradeData.decode(rows))
            let decodedManifest = try JSONDecoder().decode(DataManifest.self, from: metadata)
            try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            try JSONEncoder().encode(updated).write(to: cacheDirectory.appendingPathComponent("trades.json"), options: .atomic)
            try metadata.write(to: cacheDirectory.appendingPathComponent("manifest.json"), options: .atomic)
            trades = updated
            manifest = decodedManifest
            checkedAt = Date()
        } catch { self.error = "Refresh failed. Saved disclosures remain available. \(error.localizedDescription)" }
    }

    private func download(_ path: String) async throws -> Data {
        var request = URLRequest(url: URL(string: base + path)!)
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
