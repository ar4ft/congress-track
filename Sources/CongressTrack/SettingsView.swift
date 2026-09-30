import SwiftUI

struct AppSettingsView: View {
    @EnvironmentObject private var store: TradeStore
    @EnvironmentObject private var updates: UpdateController
    @State private var ticker = ""

    var body: some View {
        Form {
            SwiftUI.Section("App updates") {
                Text(updates.status).font(.caption).foregroundStyle(.secondary)
                Toggle("Check for updates automatically", isOn: Binding(get: { updates.automaticallyChecks }, set: updates.setAutomaticChecks))
                    .disabled(!updates.configured)
                Toggle("Download updates and install when quitting", isOn: Binding(get: { updates.automaticallyInstalls }, set: updates.setAutomaticInstalls))
                    .disabled(!updates.configured || !updates.automaticallyChecks)
                Button("Check for Updates…") { updates.checkForUpdates() }.disabled(!updates.canCheckForUpdates)
            }
            SwiftUI.Section("Watchlist alerts") {
                Toggle("Enable macOS notifications", isOn: Binding(get: { store.notificationsEnabled }, set: { value in
                    Task { await store.setNotifications(value) }
                }))
                Text(store.notificationStatus).font(.caption).foregroundStyle(.secondary)
                Text("Checks every 15 minutes while CongressTrack is running. The initial history sync establishes a baseline without sending old-filing alerts.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            SwiftUI.Section("Watched stocks") {
                HStack {
                    TextField("Ticker, e.g. NVDA", text: $ticker)
                    Button("Watch") {
                        if !store.watchedTickers.contains(ticker.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()) { store.toggleTicker(ticker) }
                        ticker = ""
                    }.disabled(ticker.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                ForEach(store.watchedTickers.sorted(), id: \.self) { value in
                    HStack { Text(value); Spacer(); Button("Remove") { store.toggleTicker(value) } }
                }
            }
            SwiftUI.Section("Historical data") {
                Text(store.dataHealth).font(.caption)
                Button("Resync all published history") { Task { await store.refresh(forceHistory: true) } }
                    .disabled(store.refreshing)
                Text("Snapshots reconcile corrections and removed rows. Source coverage remains limited to LuxAlgo's published records.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }.formStyle(.grouped).padding().frame(width: 540, height: 620)
    }
}

struct AlertsView: View {
    @EnvironmentObject private var store: TradeStore
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("New filings for followed politicians and watched stocks").foregroundStyle(.secondary)
                Spacer()
                Button("Clear alerts") { store.clearAlerts() }.disabled(store.alerts.isEmpty)
                SettingsLink { Image(systemName: "gearshape") }
            }.padding(.horizontal, 24)
            if store.alerts.isEmpty {
                ContentUnavailableView("No new watched filings", systemImage: "bell",
                                       description: Text("Follow politicians or watch tickers. New filings appear here after the first successful sync, with checks every 15 minutes while the app runs."))
            } else {
                List(store.alerts) { alert in
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(alert.member).font(.headline)
                            Text("\(alert.asset) · filed \(alert.filedAt)").foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(alert.detectedAt.formatted()).font(.caption).foregroundStyle(.secondary)
                        if let trade = store.trades.first(where: { $0.id == alert.id }), let url = trade.filingURL { Link("Filing", destination: url) }
                    }.padding(.vertical, 6)
                }
            }
        }
    }
}

struct DataHealthView: View {
    @EnvironmentObject private var store: TradeStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack { Text("Data health").font(.title2.bold()); Spacer(); Button("Done") { dismiss() } }
            Label(store.dataHealth, systemImage: "clock.badge.exclamationmark")
            Text("Published snapshot records: \(store.manifest?.datasets["congress-trades"]?.rows ?? 0) · loaded records: \(store.trades.count)")
            Text("Source ingestion: \(store.manifest?.datasets["congress-trades"]?.lastIngestedAt ?? "Unknown")")
            Text("Last full history sync: \(store.lastHistorySync?.formatted() ?? "Not yet completed")")
            ForEach(["house-clerk", "senate-efd"], id: \.self) { key in
                if let source = store.manifest?.sources?[key] {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(key).font(.headline)
                        Text("Last sync: \(source.lastSyncAt ?? "Unknown") · \(source.lastSyncOk == true ? "successful" : "failed or unknown")")
                        Text("Canary: \(source.lastCanaryStatus ?? "Unknown") · \(source.lastCanaryAt ?? "Unknown")")
                    }.font(.caption)
                }
            }
            if let error = store.error { Text(error).font(.caption).foregroundStyle(.orange) }
            Text("A recent app check does not make old source data fresh. A matching snapshot row count verifies the published archive, not complete congressional coverage.")
                .font(.caption).foregroundStyle(.secondary)
            Button("Resync all history") { Task { await store.refresh(forceHistory: true) } }.disabled(store.refreshing)
        }.padding(24).frame(width: 600)
    }
}

struct MenuBarView: View {
    @EnvironmentObject private var store: TradeStore
    @EnvironmentObject private var updates: UpdateController
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Text("CongressTrack · \(store.trades.count) disclosures").font(.headline)
        Text(store.dataHealth)
        Divider()
        ForEach(Array(store.alerts.prefix(5))) { alert in
            Text("\(alert.member) · \(alert.asset)")
        }
        Button("Open CongressTrack") {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }
        Button("Refresh disclosures") { Task { await store.refresh() } }.disabled(store.refreshing)
        SettingsLink()
        Button("Check for Updates…") { updates.checkForUpdates() }.disabled(!updates.canCheckForUpdates)
        Divider()
        Button("Quit") { NSApp.terminate(nil) }.keyboardShortcut("q")
    }
}
