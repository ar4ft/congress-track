import SwiftUI

@main
struct CongressTrackApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var store = TradeStore()
    @State private var prices = PriceStore()
    @State private var updates = UpdateController()
    var body: some Scene {
        WindowGroup("CongressTrack", id: "main") {
            ContentView().environment(store).environment(prices).environment(updates)
                .frame(minWidth: 1060, minHeight: 680)
                .tint(AppTheme.accent)
        }
        .defaultSize(width: 1380, height: 850)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") { updates.checkForUpdates() }
                    .disabled(!updates.canCheckForUpdates)
            }
            CommandGroup(after: .newItem) {
                Button("Refresh Disclosures") { Task { await store.refresh() } }
                    .keyboardShortcut("r", modifiers: .command)
                    .disabled(store.refreshing)
            }
        }
        Settings { AppSettingsView().environment(store).environment(updates) }
        MenuBarExtra("CongressTrack", systemImage: "building.columns") {
            MenuBarView().environment(store).environment(updates)
        }
    }
}
