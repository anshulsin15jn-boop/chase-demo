// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "DemoCore", platforms: [.macOS(.v14), .iOS(.v17)], products: [.library(name: "DemoCore", targets: ["DemoCore"])], targets: [.target(name: "DemoCore"), .testTarget(name: "DemoCoreTests", dependencies: ["DemoCore"])])
