import SwiftUI

struct TradeDetail: View {
    @Environment(TradeStore.self) private var store
    let trade: Trade

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("DISCLOSURE DETAILS").font(.caption.bold()).foregroundStyle(.secondary)
                Text(trade.ticker ?? trade.assetType.capitalized).font(.largeTitle.bold())
                Text(trade.assetDescription).font(.headline)
                Divider()
                Text(trade.member.name).font(.title3.bold())
                Text([trade.member.party, trade.member.state].compactMap { $0 }.joined(separator: " · "))
                    .foregroundStyle(.secondary)
                Button {
                    store.toggleFollow(trade.member)
                } label: {
                    Label(store.followed.contains(trade.member.key) ? "Following" : "Follow politician",
                          systemImage: store.followed.contains(trade.member.key) ? "star.fill" : "star")
                }.buttonStyle(.bordered)
                if let ticker = trade.ticker {
                    Button {
                        store.toggleTicker(ticker)
                    } label: {
                        Label(store.watchedTickers.contains(ticker.uppercased()) ? "Watching \(ticker)" : "Watch \(ticker)", systemImage: "bell")
                    }.buttonStyle(.bordered)
                }
                Divider()
                field("Transaction", trade.side.capitalized)
                field("Disclosed amount", trade.amountRange.text)
                field("Owner", trade.owner.capitalized)
                field("Traded", Day.display(trade.transactedAt))
                field("Filed", Day.display(trade.filedAt))
                field("Disclosure delay", trade.delay.map { "\($0) days" } ?? "Unknown")
                if trade.provenance.needsReview == true {
                    Label("Source parser flagged this record for review.", systemImage: "exclamationmark.triangle")
                        .font(.caption).foregroundStyle(.orange)
                }
                Divider()
                if let url = trade.filingURL {
                    Link(destination: url) { Label("Open original filing", systemImage: "arrow.up.right.square") }
                }
                field("Source", trade.provenance.source)
                field("Retrieved", trade.provenance.retrievedAt)
            }.padding(22)
        }
    }

    private func field(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.callout).textSelection(.enabled)
        }
    }
}
