import SwiftUI

struct ScoredPurchases: View {
    let leader: LeaderboardEntry
    var body: some View {
        DisclosureGroup("View \(leader.member.name)'s scored purchases") {
            ForEach(leader.events) { event in
                HStack {
                    Text(event.trade.ticker ?? "—").fontWeight(.semibold).frame(width: 65, alignment: .leading)
                    Text("\(event.entry) → \(event.exit)").font(.caption)
                    Spacer()
                    Text("Model \(ReturnFormat.percent(event.returnPct)) · SPY \(ReturnFormat.percent(event.benchmarkPct))").font(.caption).monospacedDigit()
                    if let url = event.trade.filingURL { Link("Filing", destination: url) }
                }.padding(.vertical, 5)
            }
        }
    }
}
