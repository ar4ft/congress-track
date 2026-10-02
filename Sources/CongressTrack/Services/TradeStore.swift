import Foundation
import Observation
import UserNotifications

@MainActor
@Observable
final class TradeStore {
    private(set) var trades: [Trade] = []
    private(set) var revision = 0
    private(set) var members: [Trade.Member] = []
    private(set) var memberCounts: [String: Int] = [:]
    private var ingestedAt: Date?
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    private var notificationRequest = UUID()
    private(set) var refreshing = false
    private(set) var manifest: DataManifest?
    private(set) var checkedAt: Date?
    private(set) var lastHistorySync: Date?
    private(set) var syncProgress = ""
    var error: String?
    private(set) var followed: Set<String>
    private(set) var watchedTickers: Set<String>
    private(set) var alerts: [DisclosureAlert] = []
    private(set) var searches: [SavedSearch] = []
    private(set) var notificationsEnabled: Bool
    private(set) var notificationStatus = "System alerts are off"

    private let defaults: UserDefaults
    private let base = "https://raw.githubusercontent.com/LuxAlgo/market-trackers-data/main/"
    private let cacheDirectory: URL
    private var pollingTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        followed = Set(defaults.stringArray(forKey: "followedMembers") ?? [])
        watchedTickers = Set(defaults.stringArray(forKey: "watchedTickers") ?? [])
        notificationsEnabled = defaults.bool(forKey: "notificationsEnabled")
        lastHistorySync = defaults.object(forKey: "lastHistorySync") as? Date
        checkedAt = defaults.object(forKey: "checkedAt") as? Date
        if let data = defaults.data(forKey: "searches"), let saved = try? JSONDecoder().decode([SavedSearch].self, from: data) { searches = saved }
        if let data = defaults.data(forKey: "alerts"), let saved = try? JSONDecoder().decode([DisclosureAlert].self, from: data) { alerts = saved }
        cacheDirectory = URL.applicationSupportDirectory.appending(path: "CongressTrack", directoryHint: .isDirectory)
        if notificationsEnabled { notificationStatus = "System alerts enabled; authorization is checked on delivery" }
    }

    func loadIfNeeded() async {
        if let loadTask { await loadTask.value; return }
        let task = Task { await loadSavedData() }
        loadTask = task
        await task.value
    }

    private func loadSavedData() async {
        do {
            let snapshotURL = cacheDirectory.appending(path: "snapshot.json")
            if let cached = try? await LocalStorage.shared.read(TradeSnapshot.self, from: snapshotURL) {
                publish(cached.trades, manifest: cached.manifest)
                return
            }
            // Preserve caches created before the atomic snapshot format was introduced.
            let seed = AppResources.url("trades", extension: "json")
            let seedManifest = AppResources.url("manifest", extension: "json")
            let saved = try? await LocalStorage.shared.read([Trade].self, from: cacheDirectory.appending(path: "trades.json"))
            let rows: [Trade]
            if let saved { rows = saved } else { rows = try await LocalStorage.shared.read([Trade].self, from: seed) }
            let metadata = try? await LocalStorage.shared.read(DataManifest.self, from: cacheDirectory.appending(path: "manifest.json"))
            let manifest: DataManifest
            if let metadata { manifest = metadata } else { manifest = try await LocalStorage.shared.read(DataManifest.self, from: seedManifest) }
            publish(TradeData.merge([], rows), manifest: manifest)
        } catch { self.error = "Could not load saved disclosures: \(error.localizedDescription)" }
    }

    private func publish(_ rows: [Trade], manifest: DataManifest) {
        trades = rows; self.manifest = manifest; revision += 1
        let groups = Dictionary(grouping: rows, by: { $0.member.key })
        members = groups.values.compactMap { $0.first?.member }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        memberCounts = groups.mapValues(\.count)
        ingestedAt = manifest.datasets["congress-trades"]?.lastIngestedAt.flatMap(parseTimestamp)
    }

    var dataHealth: String {
        guard let dataset = manifest?.datasets["congress-trades"],
              let date = ingestedAt else { return "Unknown source freshness" }
        if dataset.stale == true || Date().timeIntervalSince(date) > 72 * 3600 { return "Stale source · no ingestion within 72 hours" }
        return "Source ingestion within 72 hours"
    }

    private func parseTimestamp(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }

    func startMonitoring() {
        guard pollingTask == nil else { return }
        pollingTask = Task { [weak self] in
            await self?.loadIfNeeded()
            await self?.refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(900))
                guard !Task.isCancelled else { return }
                await self?.refresh()
            }
        }
    }

    func toggleFollow(_ member: Trade.Member) {
        if followed.contains(member.key) { followed.remove(member.key) } else { followed.insert(member.key) }
        defaults.set(Array(followed).sorted(), forKey: "followedMembers")
    }

    func toggleTicker(_ ticker: String) {
        let value = ticker.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !value.isEmpty else { return }
        if watchedTickers.contains(value) { watchedTickers.remove(value) } else { watchedTickers.insert(value) }
        defaults.set(Array(watchedTickers).sorted(), forKey: "watchedTickers")
    }

    func saveSearch(_ search: SavedSearch) {
        searches.append(search)
        defaults.set(try? JSONEncoder().encode(searches), forKey: "searches")
    }
    func deleteSearch(_ id: UUID) {
        searches.removeAll { $0.id == id }
        defaults.set(try? JSONEncoder().encode(searches), forKey: "searches")
    }
    func clearAlerts() {
        alerts = []
        defaults.removeObject(forKey: "alerts")
    }

    func setNotifications(_ enabled: Bool) async {
        let request = UUID(); notificationRequest = request
        if !enabled {
            notificationsEnabled = false; notificationStatus = "System alerts are off"
            defaults.set(false, forKey: "notificationsEnabled"); return
        }
        guard Bundle.main.bundleIdentifier == "app.congresstrack.mac" else {
            notificationStatus = "Build and launch the .app to enable macOS notifications"; return
        }
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            guard request == notificationRequest else { return }
            notificationsEnabled = granted
            notificationStatus = granted ? "System alerts enabled" : "Notifications denied; enable them in System Settings"
            defaults.set(granted, forKey: "notificationsEnabled")
        } catch { if request == notificationRequest { notificationStatus = error.localizedDescription } }
    }

    func refresh(forceHistory: Bool = false) async {
        await loadIfNeeded()
        guard !refreshing else { return }
        refreshing = true; error = nil
        defer { refreshing = false; syncProgress = "" }
        do {
            syncProgress = "Checking source manifest"
            async let rowsData = download("congress/trades/latest.json")
            async let manifestData = download("manifest.json")
            let (rows, metadata) = try await (rowsData, manifestData)
            let decodedManifest = try JSONDecoder().decode(DataManifest.self, from: metadata)
            guard let dataset = decodedManifest.datasets["congress-trades"] else { throw PriceError.message("Congress dataset is missing from the source manifest.") }
            let needsHistory = forceHistory || lastHistorySync == nil ||
                decodedManifest.generatedAt != manifest?.generatedAt ||
                Date().timeIntervalSince(lastHistorySync ?? .distantPast) > 86400
            var history = trades
            if needsHistory {
                let files = HistorySync.snapshots(dataset)
                guard !files.isEmpty else { throw PriceError.message("Source manifest lists no congressional history snapshots.") }
                history = []
                for (index, file) in files.enumerated() {
                    syncProgress = "History shard \(index + 1)/\(files.count): \(file)"
                    guard !file.contains("/"), !file.contains("..") else { throw URLError(.badURL) }
                    let compressed = try await download("congress/trades/" + file)
                    history = TradeData.merge(history, try await HistorySync.decodeGzip(compressed))
                }
                if let expected = dataset.rows, expected != history.count {
                    throw PriceError.message("Snapshot coverage mismatch: received \(history.count) of \(expected) published records. Saved history was preserved; retry sync.")
                }
            }
            let updated = TradeData.merge(history, try TradeData.decode(rows))
            try Task.checkCancellation()
            try await LocalStorage.shared.write(TradeSnapshot(trades: updated, manifest: decodedManifest),
                                                to: cacheDirectory.appending(path: "snapshot.json"))
            let matches = defaults.bool(forKey: "alertBaselineEstablished") ?
                AlertPolicy.newMatches(old: trades, new: updated, members: followed, tickers: watchedTickers) : []
            publish(updated, manifest: decodedManifest); checkedAt = Date()
            defaults.set(checkedAt, forKey: "checkedAt")
            defaults.set(true, forKey: "alertBaselineEstablished")
            if needsHistory { lastHistorySync = Date(); defaults.set(lastHistorySync, forKey: "lastHistorySync") }
            await recordAlerts(matches)
        } catch is CancellationError {
            return
        } catch { self.error = "Sync failed. Saved disclosures remain available. \(error.localizedDescription)" }
    }

    private func recordAlerts(_ matches: [Trade]) async {
        guard !matches.isEmpty else { return }
        alerts = Array((matches.map { DisclosureAlert(id: $0.id, member: $0.member.name,
                                                    asset: $0.ticker ?? $0.assetDescription, filedAt: $0.filedAt, detectedAt: Date()) } + alerts).prefix(200))
        defaults.set(try? JSONEncoder().encode(alerts), forKey: "alerts")
        guard notificationsEnabled, Bundle.main.bundleIdentifier == "app.congresstrack.mac" else { return }
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            notificationStatus = "System notifications unavailable; new filings are saved in Alerts"; return
        }
        let content = UNMutableNotificationContent()
        content.title = "\(matches.count) new watched disclosures"
        content.body = matches.prefix(3).map { "\($0.member.name): \($0.ticker ?? $0.assetDescription)" }.joined(separator: " · ")
        content.sound = .default
        do {
            try await center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
        } catch { notificationStatus = "Delivery failed: \(error.localizedDescription)" }
    }

    private func download(_ path: String) async throws -> Data {
        guard let url = URL(string: base + path) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.timeoutInterval = 30; request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw URLError(.badServerResponse) }
        return data
    }
}
