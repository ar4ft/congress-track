import SwiftUI

struct WorkspaceHeader: View {
    let title: String
    let subtitle: String
    let workspace: WorkspaceModel
    var showMetrics = true
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.largeTitle.bold())
                    Text(subtitle).font(.callout).foregroundStyle(.secondary)
                }
                Spacer()
                Label("House + Senate", systemImage: "building.columns")
                    .font(.caption.weight(.semibold)).padding(9)
                    .background(AppTheme.accent.opacity(0.1), in: .capsule)
            }
            if showMetrics {
                HStack(spacing: 12) {
                    MetricCard(title: "Disclosures", value: workspace.rows.count.formatted(), symbol: "doc.text")
                    MetricCard(title: "Politicians", value: workspace.politicianCount.formatted(), symbol: "person.2")
                    MetricCard(title: "Purchases", value: workspace.purchases.formatted(), symbol: "arrow.down.left")
                    MetricCard(title: "Sales", value: workspace.sales.formatted(), symbol: "arrow.up.right")
                }
            }
        }.padding(AppTheme.spacing)
    }
}
