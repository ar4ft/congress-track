import SwiftUI

@main
struct CongressTrackApp: App {
    @StateObject private var store = TradeStore()
    @StateObject private var prices = PriceStore()
    @StateObject private var updates = UpdateController()
    var body: some Scene {
        WindowGroup("CongressTrack", id: "main") {
            ContentView().environmentObject(store).environmentObject(prices).environmentObject(updates)
                .frame(minWidth: 1200, minHeight: 720)
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
        Settings { AppSettingsView().environmentObject(store).environmentObject(updates) }
        MenuBarExtra("CongressTrack", systemImage: "building.columns") {
            MenuBarView().environmentObject(store).environmentObject(updates)
        }
    }
}
