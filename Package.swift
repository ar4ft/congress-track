// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CongressTrack",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "CongressTrack", targets: ["CongressTrack"])],
    dependencies: [.package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0")],
    targets: [
        .executableTarget(name: "CongressTrack", dependencies: [.product(name: "Sparkle", package: "Sparkle")],
                          resources: [.process("Resources")],
                          linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])]),
        .testTarget(name: "CongressTrackTests", dependencies: ["CongressTrack"])
    ]
)
