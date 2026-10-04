import SwiftUI

struct WorkspaceSidebar: View {
    @Environment(TradeStore.self) private var store
    @Bindable var workspace: WorkspaceModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "building.columns").font(.title2).foregroundStyle(AppTheme.sidebarAccent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("CongressTrack").font(.headline).foregroundStyle(AppTheme.sidebarInk)
                    Text("Public disclosures").font(.caption).foregroundStyle(AppTheme.sidebarSecondary)
                }
            }.padding(20).padding(.top, 8)
            List(selection: $workspace.route) {
                Section("Workspace") {
                    ForEach(WorkspaceRoute.allCases) { route in
                        Label(route.title, systemImage: route.icon).tag(route)
                            .foregroundStyle(workspace.route == route ? AppTheme.sidebarAccent : AppTheme.sidebarInk)
                            .listRowBackground(workspace.route == route ? AppTheme.sidebarSelection : Color.clear)
                    }
                }
                Section("Following") {
                    if store.followed.isEmpty && store.watchedTickers.isEmpty {
                        Text("Follow a politician or stock from a disclosure.")
                            .font(.callout).foregroundStyle(AppTheme.sidebarSecondary)
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
            }
            .listStyle(.sidebar).scrollContentBackground(.hidden)
            .foregroundStyle(AppTheme.sidebarInk)
            .environment(\.colorScheme, .dark)
            .tint(AppTheme.sidebarAccent)
            VStack(alignment: .leading, spacing: 5) {
                Text("House & Senate").font(.callout).foregroundStyle(AppTheme.sidebarInk)
                Text("Data by LuxAlgo · disclosed ranges").font(.caption).foregroundStyle(AppTheme.sidebarSecondary)
            }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) { Rectangle().fill(AppTheme.sidebarSecondary.opacity(0.3)).frame(height: 1).padding(.horizontal, 20) }
        }
        .background(AppTheme.sidebar)
        .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 290)
    }
}
