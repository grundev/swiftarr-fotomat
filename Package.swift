// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "fotomat",
    products: [
        .library(name: "fotomat", targets: ["App"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
        .package(url: "https://github.com/grundoon/SwiftImageMagick", .branch("master"))
    ],
    targets: [
        .target(name: "App", dependencies: ["Vapor"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

