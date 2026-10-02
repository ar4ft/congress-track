import Foundation
import Observation
import Combine
import Sparkle

@MainActor
@Observable
final class UpdateController {
    private(set) var canCheckForUpdates = false
    var automaticallyChecks = false {
        didSet { if automaticallyChecks != oldValue { setAutomaticChecks(automaticallyChecks) } }
    }
    var automaticallyInstalls = false {
        didSet { if automaticallyInstalls != oldValue { setAutomaticInstalls(automaticallyInstalls) } }
    }
    let configured: Bool
    let status: String
    @ObservationIgnored private var controller: SPUStandardUpdaterController?
    @ObservationIgnored private var subscriptions = Set<AnyCancellable>()

    init(bundle: Bundle = .main) {
        let info = bundle.infoDictionary ?? [:]
        configured = UpdateConfiguration.isValid(info: info, bundleURL: bundle.bundleURL)
        status = configured ? "Signed updates from GitHub Releases" :
            "Updates are available in production builds configured with the release signing key."
        guard configured else { return }
        let controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        self.controller = controller
        controller.updater.publisher(for: \.canCheckForUpdates).sink { [weak self] value in
            Task { @MainActor [weak self] in self?.canCheckForUpdates = value }
        }.store(in: &subscriptions)
        controller.updater.publisher(for: \.automaticallyChecksForUpdates).sink { [weak self] value in
            Task { @MainActor [weak self] in self?.automaticallyChecks = value }
        }.store(in: &subscriptions)
        controller.updater.publisher(for: \.automaticallyDownloadsUpdates).sink { [weak self] value in
            Task { @MainActor [weak self] in self?.automaticallyInstalls = value }
        }.store(in: &subscriptions)
    }

    func checkForUpdates() { controller?.checkForUpdates(nil) }
    func setAutomaticChecks(_ value: Bool) { controller?.updater.automaticallyChecksForUpdates = value }
    func setAutomaticInstalls(_ value: Bool) { controller?.updater.automaticallyDownloadsUpdates = value }
}
