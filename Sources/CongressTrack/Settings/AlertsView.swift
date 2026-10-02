import SwiftUI

struct AlertsView: View {
    @Environment(TradeStore.self) private var store
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("New filings for followed politicians and watched stocks").foregroundStyle(.secondary)
                Spacer()
                Button("Clear alerts") { store.clearAlerts() }.disabled(store.alerts.isEmpty)
                SettingsLink { Label("Alert settings", systemImage: "gearshape").labelStyle(.iconOnly) }
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
