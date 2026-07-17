// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AgentsStatusBar",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "AgentsStatusCore", targets: ["AgentsStatusCore"]),
        .executable(name: "AgentsStatusBar", targets: ["AgentsStatusBar"]),
    ],
    targets: [
        .target(
            name: "AgentsStatusCore",
            swiftSettings: [.enableUpcomingFeature("StrictConcurrency")],
            linkerSettings: [.linkedFramework("Security", .when(platforms: [.macOS]))]),
        .executableTarget(
            name: "AgentsStatusBar",
            dependencies: ["AgentsStatusCore"],
            exclude: ["Resources"],
            swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]),
        .testTarget(
            name: "AgentsStatusCoreTests",
            dependencies: ["AgentsStatusCore"],
            resources: [.copy("Fixtures")],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
    ])
