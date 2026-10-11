// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "MemoLine",
    platforms: [.macOS(.v13)],
    targets: [
        // Resources holds the translations. scripts/build-app.sh copies them
        // into the app, so SwiftPM leaves them alone.
        .executableTarget(name: "MemoLine", path: "Sources/MemoLine", exclude: ["Resources"])
    ]
)
