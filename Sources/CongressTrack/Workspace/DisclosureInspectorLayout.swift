import SwiftUI

/// Avoid automatic inspector toolbar-separator registration and presentation
/// callbacks inside NavigationSplitView. This native resizable split pane keeps
/// disclosure presentation under the workspace's control on every supported OS.
struct DisclosureInspectorLayout<Content: View>: View {
    @Bindable var workspace: WorkspaceModel
    let content: Content

    init(workspace: WorkspaceModel, @ViewBuilder content: () -> Content) {
        self.workspace = workspace
        self.content = content()
    }

    var body: some View {
        HSplitView {
            content.frame(maxWidth: .infinity, maxHeight: .infinity)
            if workspace.showInspector {
                inspectorContent
                    .frame(minWidth: 280, idealWidth: 320, maxWidth: 420, maxHeight: .infinity)
            }
        }
    }

    private var inspectorContent: some View {
        Group {
            if let trade = workspace.selected {
                TradeDetail(trade: trade) { workspace.showInspector = false }
            } else {
                ContentUnavailableView("Select a disclosure", systemImage: "doc.text.magnifyingglass",
                                       description: Text("Choose a row to inspect its dates and original filing."))
            }
        }
        .background(AppTheme.surface)
        .accessibilityIdentifier("disclosure-inspector")
    }
}
