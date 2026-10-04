import SwiftUI

struct PoliticianCard: View {
    @Environment(TradeStore.self) private var store
    let member: Trade.Member
    let count: Int
    let open: () -> Void
    private var following: Bool { store.followed.contains(member.key) }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(member.name).font(.headline).foregroundStyle(AppTheme.ink)
                    Text([member.party, member.state].compactMap { $0 }.joined(separator: " · "))
                        .font(.caption).foregroundStyle(AppTheme.secondaryInk)
                }
                Spacer()
                Button(following ? "Unfollow \(member.name)" : "Follow \(member.name)", systemImage: following ? "star.fill" : "star") {
                    store.toggleFollow(member)
                }.labelStyle(.iconOnly).buttonStyle(.borderless)
                    .help(following ? "Unfollow politician" : "Follow politician")
            }
            HStack {
                Text("\(count.formatted()) disclosures").font(.callout).monospacedDigit().foregroundStyle(AppTheme.secondaryInk)
                Spacer()
                Button("View filings", systemImage: "arrow.right", action: open).font(.callout)
            }
        }.padding(.vertical, 16).frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .top) { Rectangle().fill(AppTheme.rule).frame(height: 1) }
    }
}
