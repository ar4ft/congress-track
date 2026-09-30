import Foundation
import SwiftUI
import Combine
import Sparkle

@MainActor
final class UpdateController: ObservableObject {
    @Published private(set) var canCheckForUpdates = false
    @Published private(set) var automaticallyChecks = false
    @Published private(set) var automaticallyInstalls = false
    let configured: Bool
    let status: String
    private var controller: SPUStandardUpdaterController?
    private var subscriptions = Set<AnyCancellable>()

    init(bundle: Bundle = .main) {
        let info = bundle.infoDictionary ?? [:]
        configured = UpdateConfiguration.isValid(info: info, bundleURL: bundle.bundleURL)
        status = configured ? "Signed updates from GitHub Releases" :
            "Updates are available in production builds configured with the release signing key."
        guard configured else { return }
        let controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        self.controller = controller
        controller.updater.publisher(for: \.canCheckForUpdates).receive(on: RunLoop.main).assign(to: &$canCheckForUpdates)
        controller.updater.publisher(for: \.automaticallyChecksForUpdates).receive(on: RunLoop.main).assign(to: &$automaticallyChecks)
        controller.updater.publisher(for: \.automaticallyDownloadsUpdates).receive(on: RunLoop.main).assign(to: &$automaticallyInstalls)
    }

    func checkForUpdates() { controller?.checkForUpdates(nil) }
    func setAutomaticChecks(_ value: Bool) { controller?.updater.automaticallyChecksForUpdates = value }
    func setAutomaticInstalls(_ value: Bool) { controller?.updater.automaticallyDownloadsUpdates = value }
}

enum UpdateConfiguration {
    static func isValid(info: [String: Any], bundleURL: URL) -> Bool {
        guard bundleURL.pathExtension == "app",
              info["CFBundleIdentifier"] as? String == "app.congresstrack.mac",
              let feed = info["SUFeedURL"] as? String, let url = URL(string: feed),
              url.scheme == "https", url.host == "github.com",
              url.path == "/ar4ft/congress-track/releases/latest/download/appcast.xml",
              let publicKey = info["SUPublicEDKey"] as? String,
              let bytes = Data(base64Encoded: publicKey), bytes.count == 32 else { return false }
        return true
    }
}
