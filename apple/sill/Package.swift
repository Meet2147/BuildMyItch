// swift-tools-version: 6.0
//
//  The whole of Sill's logic — capture parsing, day planning, calibration —
//  lives in a plain library with no Apple-framework dependencies beyond
//  Foundation. That's deliberate: it means `swift test` runs the parts most
//  likely to be wrong, on any machine, in a second, with no Xcode project and
//  no simulator. The SwiftUI app in `App/` depends on this package.

import PackageDescription

let package = Package(
    name: "SillCore",
    platforms: [.iOS(.v18), .macOS(.v15), .visionOS(.v2)],
    products: [
        .library(name: "SillCore", targets: ["SillCore"])
    ],
    targets: [
        .target(name: "SillCore"),
        .testTarget(name: "SillCoreTests", dependencies: ["SillCore"]),
    ]
)
