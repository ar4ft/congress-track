import SwiftUI

@main
struct CongressTrackApp: App {
    @StateObject private var store = TradeStore()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(store)
                .frame(minWidth: 1080, minHeight: 680)
        }
        .defaultSize(width: 1380, height: 850)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Refresh Disclosures") { Task { await store.refresh() } }
                    .keyboardShortcut("r", modifiers: .command)
                    .disabled(store.refreshing)
            }
        }
    }
}
