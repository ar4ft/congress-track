import SwiftUI

struct PoliticianCard: View {
    @Environment(TradeStore.self) private var store
    let member: Trade.Member
    let count: Int
    let open: () -> Void
    private var following: Bool { store.followed.contains(member.key) }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "person.crop.circle.fill").font(.largeTitle).foregroundStyle(AppTheme.accent)
                    .accessibilityHidden(true)
                Spacer()
                Button(following ? "Unfollow \(member.name)" : "Follow \(member.name)", systemImage: following ? "star.fill" : "star") {
                    store.toggleFollow(member)
                }.labelStyle(.iconOnly).buttonStyle(.borderless)
                    .help(following ? "Unfollow politician" : "Follow politician")
            }
            Text(member.name).font(.headline)
            Text([member.party, member.state].compactMap { $0 }.joined(separator: " · ")).font(.callout).foregroundStyle(.secondary)
            Text("\(count.formatted()) loaded disclosures").font(.callout).foregroundStyle(.secondary)
            Button("View disclosures", systemImage: "arrow.right", action: open)
        }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surface, in: .rect(cornerRadius: AppTheme.cornerRadius))
            .overlay { RoundedRectangle(cornerRadius: AppTheme.cornerRadius).strokeBorder(.quaternary) }
    }
}
