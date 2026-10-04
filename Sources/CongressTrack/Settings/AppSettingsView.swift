import SwiftUI

struct AppSettingsView: View {
    @Environment(TradeStore.self) private var store
    @Environment(UpdateController.self) private var updates
    @State private var ticker = ""
    @State private var notifications = false
    @State private var notificationRequest = UUID()

    var body: some View {
        @Bindable var updates = updates
        Form {
            SwiftUI.Section("App updates") {
                Text(updates.status).font(.caption).foregroundStyle(.secondary)
                Toggle("Check for updates automatically", isOn: $updates.automaticallyChecks)
                    .disabled(!updates.configured)
                Toggle("Download updates and install when quitting", isOn: $updates.automaticallyInstalls)
                    .disabled(!updates.configured || !updates.automaticallyChecks)
                Button("Check for Updates…") { updates.checkForUpdates() }.disabled(!updates.canCheckForUpdates)
            }
            SwiftUI.Section("Watchlist alerts") {
                Toggle("Enable macOS notifications", isOn: $notifications)
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
            .onAppear { notifications = store.notificationsEnabled }
            .onChange(of: notifications) { _, value in
                let request = UUID()
                notificationRequest = request
                Task {
                    await store.setNotifications(value)
                    guard request == notificationRequest else { return }
                    notifications = store.notificationsEnabled
                }
            }
            .onChange(of: store.notificationsEnabled) { _, value in notifications = value }
    }
}
