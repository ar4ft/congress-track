import SwiftUI

struct ExcludedPurchases: View {
    let events: [SkippedEvent]
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            Text("Excluded purchases").font(.headline)
            ForEach(events) { event in
                HStack(alignment: .top) {
                    Text("\(event.trade.member.name) · \(event.trade.ticker ?? event.trade.assetType)")
                        .frame(width: 240, alignment: .leading)
                    Text(event.reason).foregroundStyle(.secondary)
                    Spacer()
                    if let url = event.trade.filingURL { Link("Filing", destination: url) }
                }.font(.caption).padding(.vertical, 4)
            }
        }
    }
}
