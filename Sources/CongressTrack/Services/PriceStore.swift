import Foundation
import Observation

@MainActor
@Observable
final class PriceStore {
    private(set) var archive = PriceArchive()
    private(set) var revision = 0
    private(set) var latestBar: String?
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    private(set) var loading = false
    private(set) var progress = ""
    private(set) var failures: [String] = []
    var error: String?
    private let cache: URL
    init(cache: URL = URL.applicationSupportDirectory.appending(path: "CongressTrack/prices.json")) {
        self.cache = cache
    }

    func loadIfNeeded() async {
        if let loadTask { await loadTask.value; return }
        let task = Task { await loadSavedData() }
        loadTask = task
        await task.value
    }

    private func loadSavedData() async {
        if let saved = try? await LocalStorage.shared.read(PriceArchive.self, from: cache) { publish(saved) }
    }

    private func publish(_ updated: PriceArchive) {
        archive = updated; revision += 1
        latestBar = updated.series.values.compactMap { $0.last?.date }.max()
    }

    func refresh(for trades: [Trade]) async {
        await loadIfNeeded()
        guard !loading else { return }
        loading = true; failures = []; error = nil
        defer { loading = false; progress = "" }
        let candidates = trades.filter { $0.side == "buy" && $0.assetType == "stock" && $0.ticker != nil }
        let tickers = Set(candidates.compactMap { $0.ticker?.uppercased() }).union(["SPY"]).sorted()
        let since = candidates.compactMap { Day.parse($0.filedAt) }.min() ?? Day.adding(-730, to: Date())
        var updated = archive
        do {
            for (index, ticker) in tickers.enumerated() {
                try Task.checkCancellation()
                progress = "\(ticker) · \(index + 1) of \(tickers.count)"
                do {
                    let bars = try await fetch(ticker: ticker, since: Day.adding(-7, to: since))
                    // Replace the whole downloaded interval to retain adjusted-price revisions.
                    updated.series[ticker] = bars
                    updated.sources[ticker] = "Yahoo Finance adjusted close (unofficial endpoint)"
                } catch is CancellationError { throw CancellationError()
                } catch {
                    try Task.checkCancellation()
                    failures.append("\(ticker): \(error.localizedDescription)")
                }
            }
            updated.updatedAt = Date()
            try Task.checkCancellation()
            try await LocalStorage.shared.write(updated, to: cache)
            publish(updated)
            if !failures.isEmpty { error = "\(failures.count) ticker downloads failed. Cached prices are retained; coverage may be incomplete." }
    
        } catch is CancellationError { return
        } catch { self.error = "Could not save prices: \(error.localizedDescription)" }
    }

    func importCSV(_ url: URL) async {
        guard !loading else { return }
        loading = true
        defer { loading = false }
        do {
            let updated = try await LocalStorage.shared.importPrices(from: url)
            try await LocalStorage.shared.write(updated, to: cache)
            publish(updated); failures = []; error = nil
        } catch is CancellationError { return
        } catch { self.error = error.localizedDescription }
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
