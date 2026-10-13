import AppKit
import SwiftUI
import XCTest
@testable import CongressTrack

final class WindowLayoutTests: XCTestCase {
    @MainActor
    func testWindowLaunchSelectionInspectorResizeAndClose() async throws {
        _ = NSApplication.shared
        let suite = "CongressTrack.window-tests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = TradeStore(defaults: defaults)
        await store.loadIfNeeded()
        let workspace = WorkspaceModel()
        let query = TradeQuery(revision: store.revision, filters: workspace.filters,
                               watchlistOnly: false, members: [], tickers: [])
        await workspace.refresh(store.trades, query: query)
        let selected = try XCTUnwrap(workspace.rows.first)
        let cache = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + ".json")
        let root = ContentView(workspace: workspace, startsMonitoring: false)
            .environment(store).environment(PriceStore(cache: cache)).environment(UpdateController())
        let window = NSWindow(contentViewController: NSHostingController(rootView: root))
        window.isReleasedWhenClosed = false
        defer { window.close() }
        window.setContentSize(NSSize(width: 1380, height: 850))
        window.makeKeyAndOrderFront(nil)
        try await render(window)
        XCTAssertTrue(window.isVisible)
        XCTAssertFalse(workspace.showInspector)

        workspace.selectedID = selected.id
        try await render(window)
        XCTAssertTrue(workspace.showInspector)
        XCTAssertEqual(workspace.selected?.id, selected.id)

        window.setContentSize(NSSize(width: 1060, height: 680))
        try await render(window)
        XCTAssertTrue(window.isVisible)
        workspace.showInspector = false
        try await render(window)
        XCTAssertFalse(workspace.showInspector)
        XCTAssertEqual(workspace.selected?.id, selected.id, "Closing details must preserve the selected filing")
        workspace.showInspector = true
        try await render(window)
        XCTAssertTrue(workspace.showInspector)
    }

    @MainActor
    private func render(_ window: NSWindow) async throws {
        try await Task.sleep(for: .milliseconds(200))
        window.layoutIfNeeded()
        window.displayIfNeeded()
        NSApplication.shared.updateWindows()
    }
}
