import SwiftUI

struct TradeDetail: View {
    @Environment(TradeStore.self) private var store
    @ScaledMetric(relativeTo: .largeTitle) private var tickerSize = 40.0
    let trade: Trade
    let close: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Disclosure details").font(.caption).foregroundStyle(AppTheme.secondaryInk)
                Spacer()
                Button("Close", action: close).help("Close disclosure details (⌘⌥I)")
            }.padding(.horizontal, 22).padding(.vertical, 12)
                .overlay(alignment: .bottom) { Rectangle().fill(AppTheme.rule).frame(height: 1) }
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(trade.ticker ?? trade.assetType.capitalized)
                        .font(.system(size: tickerSize, weight: .bold).width(.condensed)).tracking(-0.8)
                        .foregroundStyle(AppTheme.ink)
                    Text(trade.assetDescription).font(.callout).foregroundStyle(AppTheme.secondaryInk).textSelection(.enabled)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trade.member.name).font(.headline).foregroundStyle(AppTheme.ink)
                        Text([trade.member.party, trade.member.state].compactMap { $0 }.joined(separator: " · "))
                            .font(.caption).foregroundStyle(AppTheme.secondaryInk)
                    }
                    HStack {
                        Button {
                            store.toggleFollow(trade.member)
                        } label: {
                            Label(store.followed.contains(trade.member.key) ? "Following" : "Follow",
                                  systemImage: store.followed.contains(trade.member.key) ? "star.fill" : "star")
                        }.help("Follow or unfollow \(trade.member.name)")
                        if let ticker = trade.ticker {
                            Button {
                                store.toggleTicker(ticker)
                            } label: {
                                Label(store.watchedTickers.contains(ticker.uppercased()) ? "Watching \(ticker)" : "Watch \(ticker)", systemImage: "bell")
                            }
                        }
                    }.buttonStyle(.bordered).controlSize(.small)
                    DisclosureTimeline(trade: trade)
                    DisclosureField(title: "Disclosed amount", value: trade.amountRange.text)
                    HStack(alignment: .top) {
                        DisclosureField(title: "Transaction", value: trade.side.capitalized)
                        Spacer()
                        DisclosureField(title: "Owner", value: trade.owner.capitalized, alignment: .trailing)
                    }
                    if trade.provenance.needsReview == true {
                        Label("Source parser flagged this record for review.", systemImage: "exclamationmark.triangle")
                            .font(.caption).foregroundStyle(AppTheme.accent)
                    }
                    DisclosureField(title: "Source", value: trade.provenance.source)
                    DisclosureField(title: "Retrieved", value: SourceTimestamp.display(trade.provenance.retrievedAt))
                        .help(trade.provenance.retrievedAt)
                    DisclosureGroup("Exact retrieval timestamp") {
                        Text(trade.provenance.retrievedAt).font(.caption).textSelection(.enabled)
                    }.font(.caption).foregroundStyle(AppTheme.secondaryInk)
                }.frame(maxWidth: .infinity, alignment: .leading).padding(22)
            }
            .scrollIndicators(.visible)
            VStack(alignment: .leading, spacing: 4) {
                if let url = trade.filingURL {
                    Link(destination: url) {
                        Label("Open original filing", systemImage: "arrow.up.right.square")
                            .frame(maxWidth: .infinity)
                    }.buttonStyle(.borderedProminent).foregroundStyle(AppTheme.onAccent)
                } else {
                    Text("Original filing link unavailable").font(.callout).foregroundStyle(AppTheme.secondaryInk)
                }
            }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.surface)
                .overlay(alignment: .top) { Rectangle().fill(AppTheme.rule).frame(height: 1) }
        }.background(AppTheme.surface)
    }
}
