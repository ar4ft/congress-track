# Inspector startup compatibility

An Intel launch report on macOS 15.4 shows an Objective-C exception while AppKit's `NSWindowSectionController.registerSeparator` creates the SwiftUI window toolbar. AppKit then deliberately traps in `_crashOnException`, producing `EXC_BAD_INSTRUCTION`. The binary has already loaded and is running native x86-64 code; this is not evidence of an unsupported CPU instruction or a signing rejection. The report does not contain the exception's reason string.

The existing detail view combines `NavigationSplitView`, a native `.inspector`, and toolbar items. `DisclosureInspectorLayout` avoids automatic inspector/toolbar-separator registration using an AppKit-backed `HSplitView` with a resizable 280–420-point details pane on every supported macOS version. It preserves the selected disclosure, original-source action, Close, and the toolbar/keyboard toggle. An empty inspector has concrete placeholder content.

`WindowLayoutTests` hosts the actual `ContentView` in a real `NSWindow`, renders it, selects a disclosure, opens its details, resizes to the minimum window, closes details without clearing selection, and reopens them. Background monitoring is disabled only in this test, using the same production UI and bundled records.

The main CI build uses the explicit `macos-15-intel` runner. Additional launch jobs use Apple silicon on macOS 15 and 26 to exercise the same presentation across macOS generations. The packaged-app smoke check requires a large main window to appear and the app to survive startup for ten seconds. A live process alone no longer satisfies the check. All launch jobs must pass before the unsigned prerelease publishes.

Hosted runners use their current macOS point release; this does not reproduce macOS 15.4 exactly. A corrected prerelease still needs confirmation on the originally affected machine. Production certificate signing and notarization remain limited to the manually selected signed-release workflow.

The first macOS 26 regression run also caught the native inspector setting its presentation binding back to true after Close. The split-pane implementation passed the Intel tests and is now used consistently, avoiding both automatic separator registration and the competing native presentation callback. The close assertion remains in the test.
