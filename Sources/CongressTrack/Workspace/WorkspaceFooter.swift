import SwiftUI

struct WorkspaceFooter: View {
    @Environment(TradeStore.self) private var store
    @Binding var showHealth: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { freshness; Spacer(); recordCount }
                freshness
            }
            if !store.syncProgress.isEmpty { Text(store.syncProgress) }
        }
        .font(.caption).foregroundStyle(AppTheme.secondaryInk).padding(.horizontal, AppTheme.spacing).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading).background(AppTheme.canvas)
        .overlay(alignment: .top) { Rectangle().fill(AppTheme.rule).frame(height: 1) }
    }
    private var freshness: some View {
        HStack(spacing: 8) {
            if store.refreshing { ProgressView().controlSize(.mini) }
            Text(store.dataHealth).lineLimit(1).help(store.dataHealth)
            Button("Data health") { showHealth = true }.buttonStyle(.link).fixedSize()
        }
    }
    private var recordCount: some View {
        Text("\(store.trades.count.formatted()) published records · partial coverage").monospacedDigit().fixedSize()
    }
}
