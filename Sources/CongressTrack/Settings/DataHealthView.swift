import SwiftUI

struct DataHealthView: View {
    @Environment(TradeStore.self) private var store
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
