import SwiftUI

struct ContentView: View {
    @Environment(TradeStore.self) private var store
    @State private var workspace = WorkspaceModel()
    @State private var showSaveSearch = false
    @State private var searchName = ""
    @State private var showHealth = false
    private var query: TradeQuery {
        TradeQuery(revision: store.revision, filters: workspace.filters, watchlistOnly: workspace.route == .watchlist,
                   members: store.followed, tickers: store.watchedTickers)
    }
    private var showsDisclosures: Bool {
        workspace.route != .leaderboard && workspace.route != .members && workspace.route != .alerts
    }
    var body: some View {
        @Bindable var workspace = workspace
        NavigationSplitView {
            WorkspaceSidebar(workspace: workspace)
        } detail: {
            VStack(alignment: .leading, spacing: 0) {
                WorkspaceHeader(title: workspace.route?.title ?? "Disclosures",
                                subtitle: workspace.route == .leaderboard ? "Compare disclosure-following returns with the S&P 500." : "Follow the filings. Explore the full disclosure.",
                                workspace: workspace, showMetrics: showsDisclosures)
                if let error = store.error {
                    HStack {
                        Label(error, systemImage: "exclamationmark.triangle")
                        Spacer()
                        Button("Dismiss") { store.error = nil }
                    }.font(.callout).padding(12).background(.orange.opacity(0.1))
                }
                switch workspace.route {
                case .leaderboard: LeaderboardView()
                case .members: PoliticiansView(workspace: workspace)
                case .alerts: AlertsView()
                default:
                    TradeFilterBar(workspace: workspace) {
                        searchName = workspace.filters.search.isEmpty ? "Saved filters" : workspace.filters.search
                        showSaveSearch = true
                    }
                    TradeTable(workspace: workspace)
                }
                WorkspaceFooter(showHealth: $showHealth)
            }
            .background(AppTheme.canvas)
            .inspector(isPresented: $workspace.showInspector) {
                if let trade = workspace.selected {
                    TradeDetail(trade: trade)
                        .inspectorColumnWidth(min: 280, ideal: 320, max: 420)
                }
            }
            .toolbar {
                ToolbarItem {
                    Button("Refresh disclosures", systemImage: "arrow.clockwise") { Task { await store.refresh() } }
                        .labelStyle(.iconOnly).disabled(store.refreshing).help("Refresh disclosures (⌘R)")
                }
                ToolbarItem {
                    Button("Disclosure details", systemImage: "sidebar.trailing") { workspace.showInspector.toggle() }
                        .labelStyle(.iconOnly).disabled(workspace.selected == nil).help("Show or hide disclosure details")
                }
            }
        }
        .searchable(text: $workspace.filters.search, prompt: "Politician, ticker, or asset")
        .task { store.startMonitoring() }
        .task(id: query) { await workspace.refresh(store.trades, query: query) }
        .onChange(of: workspace.route) { _, _ in workspace.applyRoute(searches: store.searches) }
        .onChange(of: workspace.sortOrder) { _, _ in workspace.sort() }
        .onChange(of: workspace.selectedID) { _, value in workspace.showInspector = value != nil }
        .onChange(of: store.searches.map(\.id)) { _, ids in
            if case .savedSearch(let id) = workspace.route, !ids.contains(id) { workspace.route = .all }
        }
        .alert("Save search", isPresented: $showSaveSearch) {
            TextField("Search name", text: $searchName)
            Button("Save") { store.saveSearch(workspace.filters.saved(name: searchName.trimmingCharacters(in: .whitespacesAndNewlines))) }
                .disabled(searchName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showHealth) { DataHealthView().environment(store) }
    }
}
