// swift-tools-version: 6.0
import PackageDescription

// 쉬었음 앱의 계산 로직만 모은 패키지.
// UI가 없어서 `swift test`로 빠르게 검증할 수 있습니다.
let package = Package(
    name: "RestCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "RestCore", targets: ["RestCore"]),
    ],
    targets: [
        .target(name: "RestCore"),
        .testTarget(name: "RestCoreTests", dependencies: ["RestCore"]),
    ]
)
