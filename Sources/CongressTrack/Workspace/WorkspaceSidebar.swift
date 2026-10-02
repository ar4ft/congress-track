import SwiftUI

struct WorkspaceSidebar: View {
    @Environment(TradeStore.self) private var store
    @Bindable var workspace: WorkspaceModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "building.columns.fill").font(.title2).foregroundStyle(AppTheme.accent)
                VStack(alignment: .leading, spacing: 3) {
                    Text("CongressTrack").font(.headline)
                    Text("The public record").font(.caption).foregroundStyle(.secondary)
                }
            }.padding(20)
            List(selection: $workspace.route) {
                Section("Workspace") {
                    ForEach(WorkspaceRoute.allCases) { route in
                        Label(route.title, systemImage: route.icon).tag(route)
                    }
                }
                Section("Following") {
                    if store.followed.isEmpty && store.watchedTickers.isEmpty {
                        Text("Follow a politician or stock from a disclosure.").font(.callout).foregroundStyle(.secondary)
                    }
                    ForEach(store.members.filter { store.followed.contains($0.key) }, id: \.key) { member in
                        Label(member.name, systemImage: "person.crop.circle").tag(WorkspaceRoute.member(member.key))
                            .contextMenu { Button("Unfollow politician") { store.toggleFollow(member) } }
                    }
                    ForEach(store.watchedTickers.sorted(), id: \.self) { ticker in
                        Label(ticker, systemImage: "chart.line.uptrend.xyaxis").tag(WorkspaceRoute.ticker(ticker))
                            .contextMenu { Button("Unwatch \(ticker)") { store.toggleTicker(ticker) } }
                    }
                }
                Section("Saved searches") {
                    ForEach(store.searches) { saved in
                        Label(saved.name, systemImage: "line.3.horizontal.decrease.circle").tag(WorkspaceRoute.savedSearch(saved.id))
                            .contextMenu { Button("Delete search") { store.deleteSearch(saved.id) } }
                    }
                }
            }.listStyle(.sidebar)
            VStack(alignment: .leading, spacing: 6) {
                Label("Public disclosures", systemImage: "checkmark.seal").font(.callout.weight(.medium))
                Text("House & Senate · LuxAlgo\nAmounts are disclosed ranges.").font(.caption).foregroundStyle(.secondary)
            }.padding(20)
        }
        .navigationSplitViewColumnWidth(min: 210, ideal: 240, max: 290)
    }
}
