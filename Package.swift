// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CongressTrack",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "CongressTrack", targets: ["CongressTrack"])],
    targets: [
        .executableTarget(name: "CongressTrack", resources: [.process("Resources")]),
        .testTarget(name: "CongressTrackTests", dependencies: ["CongressTrack"])
    ]
)
