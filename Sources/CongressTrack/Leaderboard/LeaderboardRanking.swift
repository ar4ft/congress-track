import SwiftUI

struct LeaderboardRanking: View {
    @Bindable var model: LeaderboardModel
    var body: some View {
        LazyVStack(spacing: 0) {
            HStack {
                Text("Rank / politician").frame(maxWidth: .infinity, alignment: .leading)
                Text("Model").frame(width: 95, alignment: .trailing)
                Text("SPY").frame(width: 95, alignment: .trailing)
                Text("Excess").frame(width: 95, alignment: .trailing)
                Text("Scored / skipped").frame(width: 115, alignment: .trailing)
            }.font(.caption.bold()).foregroundStyle(.secondary).padding(12)
            ForEach(model.leaders.enumerated(), id: \.element.id) { index, leader in
                Button { model.selectedID = leader.id } label: {
                    HStack {
                        Text("\(index + 1)").font(.headline).monospacedDigit().frame(width: 28)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(leader.member.name).fontWeight(.medium)
                            Text([leader.member.party, leader.member.state].compactMap { $0 }.joined(separator: " · "))
                                .font(.caption).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        Text(ReturnFormat.percent(leader.returnPct)).frame(width: 95, alignment: .trailing)
                        Text(ReturnFormat.percent(leader.benchmarkPct)).frame(width: 95, alignment: .trailing)
                        Text(ReturnFormat.points(leader.excessPct)).frame(width: 95, alignment: .trailing)
                        Text("\(leader.events.count) / \(leader.skipped.count)").frame(width: 115, alignment: .trailing)
                    }.monospacedDigit().padding(12).contentShape(Rectangle())
                        .background(model.selected?.id == leader.id ? .teal.opacity(0.1) : .clear)
                }.buttonStyle(.plain)
                    .accessibilityLabel("Rank \(index + 1), \(leader.member.name). Model \(ReturnFormat.percent(leader.returnPct)), SPY \(ReturnFormat.percent(leader.benchmarkPct)), excess \(ReturnFormat.points(leader.excessPct)).")
                    .accessibilityAddTraits(model.selected?.id == leader.id ? .isSelected : [])
                Divider()
            }
        }.background(AppTheme.surface, in: .rect(cornerRadius: AppTheme.cornerRadius))
    }
}
