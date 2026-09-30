import XCTest
@testable import CongressTrack

final class UpdateTests: XCTestCase {
    private var info: [String: Any] {
        ["CFBundleIdentifier": "app.congresstrack.mac",
         "SUFeedURL": "https://github.com/ar4ft/congress-track/releases/latest/download/appcast.xml",
         "SUPublicEDKey": Data(repeating: 1, count: 32).base64EncodedString()]
    }
    func testUpdaterRequiresPackagedAppAndPinnedReleaseFeed() {
        let app = URL(fileURLWithPath: "/Applications/CongressTrack.app")
        XCTAssertTrue(UpdateConfiguration.isValid(info: info, bundleURL: app))
        XCTAssertFalse(UpdateConfiguration.isValid(info: info, bundleURL: URL(fileURLWithPath: "/tmp/CongressTrack")))
        var invalid = info; invalid["SUFeedURL"] = "https://example.com/appcast.xml"
        XCTAssertFalse(UpdateConfiguration.isValid(info: invalid, bundleURL: app))
    }
    func testUpdaterDoesNotStartWithoutValidPublicKey() {
        var invalid = info; invalid["SUPublicEDKey"] = "placeholder"
        XCTAssertFalse(UpdateConfiguration.isValid(info: invalid, bundleURL: URL(fileURLWithPath: "/Applications/CongressTrack.app")))
    }
}
