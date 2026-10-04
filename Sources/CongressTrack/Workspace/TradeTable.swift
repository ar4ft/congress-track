import SwiftUI

struct TradeTable: View {
    @Environment(TradeStore.self) private var store
    @Bindable var workspace: WorkspaceModel
    var body: some View {
        Table(workspace.rows, selection: $workspace.selectedID, sortOrder: $workspace.sortOrder) {
            TableColumn("Politician", value: \.member.name) { trade in
                VStack(alignment: .leading, spacing: 4) {
                    Text(trade.member.name).fontWeight(.semibold)
                    Text([trade.member.party, trade.member.state, trade.chamber.capitalized]
                        .compactMap { $0 }.joined(separator: " · "))
                        .font(.caption).foregroundStyle(.secondary)
                }.padding(.vertical, 4)
            }.width(min: 155, ideal: 200)
            TableColumn("Asset", value: \.assetDescription) { trade in
                VStack(alignment: .leading, spacing: 4) {
                    Text(trade.ticker ?? trade.assetType.capitalized).fontWeight(.semibold)
                    Text(trade.assetDescription).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }.help(trade.assetDescription)
            }.width(min: 120, ideal: 190)
            TableColumn("Type", value: \.side) { trade in
                Text(trade.side.capitalized).font(.caption.bold())
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(AppTheme.rule.opacity(0.45), in: .rect(cornerRadius: 4))
            }.width(75)
            TableColumn("Disclosed range") { trade in
                Text(trade.amountRange.text).font(.caption).monospacedDigit()
            }.width(min: 140, ideal: 165)
            TableColumn("Filed", value: \.filedAt) { trade in
                Text(Day.display(trade.filedAt)).monospacedDigit()
            }.width(min: 100, ideal: 115)
        }
        .scrollContentBackground(.hidden)
        .scrollIndicators(.visible)
        .background(AppTheme.canvas)
        .overlay {
            if workspace.rows.isEmpty && !workspace.filtering {
                if workspace.route == .watchlist {
                    WatchlistEmptyState(hasFollowing: !store.followed.isEmpty || !store.watchedTickers.isEmpty) {
                        workspace.clearFilters()
                        workspace.route = .all
                    }
                } else {
                    ContentUnavailableView {
                        Label("No matching disclosures", systemImage: "magnifyingglass")
                    } description: {
                        Text("Try another search or clear your filters.")
                    } actions: {
                        Button("Clear filters") { workspace.clearFilters() }
                            .buttonStyle(.borderedProminent).foregroundStyle(AppTheme.onAccent)
                    }
                }
            }
        }
    }
}
