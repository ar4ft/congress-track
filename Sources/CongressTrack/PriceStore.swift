import Foundation
import SwiftUI

struct YahooChart: Decodable {
    struct Chart: Decodable {
        struct Result: Decodable {
            struct Indicators: Decodable {
                struct Adjusted: Decodable { let adjclose: [Double?] }
                let adjclose: [Adjusted]?
            }
            let timestamp: [Int]?
            let indicators: Indicators
        }
        let result: [Result]?
    }
    let chart: Chart

    func bars() throws -> [PriceBar] {
        guard let result = chart.result?.first, let times = result.timestamp,
              let closes = result.indicators.adjclose?.first?.adjclose, times.count == closes.count else {
            throw PriceError.message("Provider did not return adjusted daily prices.")
        }
        let rows = zip(times, closes).compactMap { timestamp, value -> PriceBar? in
            guard let value, value.isFinite, value > 0 else { return nil }
            return PriceBar(date: Day.string(Date(timeIntervalSince1970: Double(timestamp))), close: value)
        }
        guard !rows.isEmpty else { throw PriceError.message("Provider returned no usable prices.") }
        // Today's quote can still be an intraday close; use completed UTC dates only.
        return rows.filter { $0.date < Day.string(Date()) }.sorted { $0.date < $1.date }
    }
}

@MainActor
final class PriceStore: ObservableObject {
    @Published private(set) var archive = PriceArchive()
    @Published private(set) var loading = false
    @Published private(set) var progress = ""
    @Published private(set) var failures: [String] = []
    @Published var error: String?
    private let cache = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("CongressTrack/prices.json")

    init() {
        if let data = try? Data(contentsOf: cache), let saved = try? JSONDecoder().decode(PriceArchive.self, from: data) { archive = saved }
    }

    func refresh(for trades: [Trade]) async {
        guard !loading else { return }
        loading = true; failures = []; error = nil
        defer { loading = false; progress = "" }
        let candidates = trades.filter { $0.side == "buy" && $0.assetType == "stock" && $0.ticker != nil }
        let tickers = Set(candidates.compactMap { $0.ticker?.uppercased() }).union(["SPY"]).sorted()
        let since = candidates.compactMap { Day.parse($0.filedAt) }.min() ?? Day.adding(-730, to: Date())
        var updated = archive
        for (index, ticker) in tickers.enumerated() {
            if Task.isCancelled { break }
            progress = "\(ticker) · \(index + 1) of \(tickers.count)"
            do {
                let bars = try await fetch(ticker: ticker, since: Day.adding(-7, to: since))
                // Replace the whole downloaded interval to retain adjusted-price revisions.
                updated.series[ticker] = bars
                updated.sources[ticker] = "Yahoo Finance adjusted close (unofficial endpoint)"
            } catch { failures.append("\(ticker): \(error.localizedDescription)") }
        }
        updated.updatedAt = Date()
        archive = updated
        do { try save() } catch { self.error = "Could not save prices: \(error.localizedDescription)" }
        if !failures.isEmpty { error = "\(failures.count) ticker downloads failed. Cached prices are retained; coverage may be incomplete." }
    }

    func importCSV(_ url: URL) {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        do {
            let parsed = try PriceCSV.parse(String(contentsOf: url, encoding: .utf8))
            // Import is a replacement, so prices from different sources aren't silently mixed.
            archive = PriceArchive(series: parsed,
                                   sources: Dictionary(uniqueKeysWithValues: parsed.keys.map { ($0, "Imported adjusted-close CSV") }),
                                   updatedAt: Date())
            failures = []; error = nil
            try save()
        } catch { self.error = error.localizedDescription }
    }

    private func save() throws {
        try FileManager.default.createDirectory(at: cache.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(archive).write(to: cache, options: .atomic)
    }

    private func fetch(ticker: String, since: Date) async throws -> [PriceBar] {
        let symbol = ticker.replacingOccurrences(of: ".", with: "-")
        var components = URLComponents()
        components.scheme = "https"; components.host = "query1.finance.yahoo.com"
        components.path = "/v8/finance/chart/" + symbol
        components.queryItems = [URLQueryItem(name: "period1", value: String(Int(since.timeIntervalSince1970))),
                                 URLQueryItem(name: "period2", value: String(Int(Date().timeIntervalSince1970))),
                                 URLQueryItem(name: "interval", value: "1d")]
        guard let url = components.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.setValue("CongressTrack/0.2", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 20
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode(YahooChart.self, from: data).bars()
    }
}
