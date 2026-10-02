import SwiftUI

struct PoliticiansView: View {
    @Environment(TradeStore.self) private var store
    let workspace: WorkspaceModel
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 16)], spacing: 16) {
                ForEach(store.members.filter { workspace.filters.search.isEmpty || $0.name.localizedStandardContains(workspace.filters.search) }, id: \.key) { member in
                    PoliticianCard(member: member, count: store.memberCounts[member.key] ?? 0) {
                        workspace.route = .member(member.key)
                    }
                }
            }.padding(AppTheme.spacing)
        }
        .overlay {
            if store.members.isEmpty {
                ContentUnavailableView("No politicians loaded", systemImage: "person.2",
                                       description: Text("Refresh disclosures to load the published records."))
            }
        }
    }
}
