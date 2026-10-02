import SwiftUI

struct TradeTable: View {
    @Environment(TradeStore.self) private var store
    @Bindable var workspace: WorkspaceModel
    var body: some View {
        Table(workspace.rows, selection: $workspace.selectedID, sortOrder: $workspace.sortOrder) {
            TableColumn("Politician", value: \.member.name) { trade in
                VStack(alignment: .leading, spacing: 4) {
                    Text(trade.member.name).fontWeight(.medium)
                    Text([trade.member.party, trade.member.state, trade.chamber.capitalized]
                        .compactMap { $0 }.joined(separator: " · "))
                        .font(.caption).foregroundStyle(.secondary)
                }.padding(.vertical, 6)
            }.width(min: 155, ideal: 200)
            TableColumn("Asset", value: \.assetDescription) { trade in
                VStack(alignment: .leading, spacing: 4) {
                    Text(trade.ticker ?? trade.assetType.capitalized).fontWeight(.semibold)
                    Text(trade.assetDescription).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }.help(trade.assetDescription)
            }.width(min: 120, ideal: 190)
            TableColumn("Type", value: \.side) { trade in
                Text(trade.side.capitalized).font(.caption.bold())
                    .foregroundStyle(trade.side == "buy" ? .teal : trade.side == "sell" ? .orange : .secondary)
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(.quaternary, in: Capsule())
            }.width(75)
            TableColumn("Disclosed range") { trade in
                Text(trade.amountRange.text).font(.caption).monospacedDigit()
            }.width(min: 140, ideal: 165)
            TableColumn("Filed", value: \.filedAt) { trade in
                Text(Day.display(trade.filedAt)).monospacedDigit()
            }.width(min: 100, ideal: 115)
        }
        .overlay {
            if workspace.rows.isEmpty && !workspace.filtering {
                ContentUnavailableView(
                    workspace.route == .watchlist && store.followed.isEmpty && store.watchedTickers.isEmpty ? "Your watchlist is empty" : "No matching disclosures",
                    systemImage: workspace.route == .watchlist ? "star" : "magnifyingglass",
                    description: Text(workspace.route == .watchlist && store.followed.isEmpty && store.watchedTickers.isEmpty ?
                        "Select a disclosure and follow its politician to get started." : "Try another search or clear your filters."))
            }
        }
    }
}
