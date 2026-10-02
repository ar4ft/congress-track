import Foundation
import Observation
import Combine
import Sparkle

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
