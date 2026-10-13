import SwiftUI

/// Older AppKit versions can crash registering the automatic inspector toolbar
/// separator inside a NavigationSplitView. A native resizable split pane avoids
/// that registration while preserving the disclosure controls and selection.
struct DisclosureInspectorLayout<Content: View>: View {
    @Bindable var workspace: WorkspaceModel
    let content: Content

    init(workspace: WorkspaceModel, @ViewBuilder content: () -> Content) {
        self.workspace = workspace
        self.content = content()
    }

    var body: some View {
        if #available(macOS 26, *) {
            content.inspector(isPresented: $workspace.showInspector) {
                inspectorContent.inspectorColumnWidth(min: 280, ideal: 320, max: 420)
            }
        } else {
            HSplitView {
                content.frame(maxWidth: .infinity, maxHeight: .infinity)
                if workspace.showInspector {
                    inspectorContent
                        .frame(minWidth: 280, idealWidth: 320, maxWidth: 420, maxHeight: .infinity)
                }
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
