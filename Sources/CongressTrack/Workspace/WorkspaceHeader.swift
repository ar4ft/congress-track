import SwiftUI

struct WorkspaceHeader: View {
    let title: String
    let subtitle: String
    let workspace: WorkspaceModel
    var showMetrics = true
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("House + Senate").font(.caption).foregroundStyle(AppTheme.secondaryInk)
            Text(title).font(AppTheme.screenTitle).tracking(-0.8).foregroundStyle(AppTheme.ink)
            if showMetrics {
                Text("\(workspace.rows.count.formatted()) disclosures · \(workspace.politicianCount.formatted()) politicians · \(workspace.purchases.formatted()) purchases · \(workspace.sales.formatted()) sales")
                    .font(.callout).monospacedDigit().foregroundStyle(AppTheme.secondaryInk)
                    .accessibilityLabel("\(workspace.rows.count) matching disclosures, \(workspace.politicianCount) politicians, \(workspace.purchases) purchases and \(workspace.sales) sales. Exchanges are included in the disclosure total.")
            } else {
                Text(subtitle).font(.callout).foregroundStyle(AppTheme.secondaryInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppTheme.spacing).padding(.top, 22).padding(.bottom, 20)
    }
}
