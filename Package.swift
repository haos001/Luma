// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Luma",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "LumaApp", targets: ["LumaApp"]),
        .executable(name: "lumactl", targets: ["LightCLI"])
    ],
    targets: [
        .target(name: "LightCore", linkerSettings: [.linkedFramework("IOKit")]),
        .executableTarget(name: "LumaApp", dependencies: ["LightCore"]),
        .executableTarget(name: "LightCLI", dependencies: ["LightCore"]),
        // No XCTest dependency: also runs with Command Line Tools alone.
        .executableTarget(name: "LightCoreChecks", dependencies: ["LightCore"], path: "Tests/LightCoreTests")
    ]
)
