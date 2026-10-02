import SwiftUI

struct WorkspaceFooter: View {
    @Environment(TradeStore.self) private var store
    @Binding var showHealth: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("\(store.trades.count.formatted()) records · \(store.dataHealth)", systemImage: "externaldrive.badge.checkmark")
                Spacer()
                if store.refreshing { ProgressView().controlSize(.mini) }
                Button("Data health") { showHealth = true }
            }
            if !store.syncProgress.isEmpty { Text(store.syncProgress) }
            Text("Disclosures are delayed; amounts are ranges. Coverage reflects the source's published records.")
        }.font(.caption).foregroundStyle(.secondary).padding(14).background(.bar)
    }
}
