import SwiftUI

struct MenuBarView: View {
    @Environment(TradeStore.self) private var store
    @Environment(UpdateController.self) private var updates
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
