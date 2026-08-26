// swift-tools-version: 6.0
//
//  AubadeCore is the part that has to be right: when to ring inside the
//  window, how the volume rises, and what a snooze costs. No AVFoundation, no
//  UserNotifications, no AlarmKit — so `swift test` proves it in a second, and
//  the scary platform work is isolated behind one protocol in the app.

import PackageDescription

let package = Package(
    name: "AubadeCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "AubadeCore", targets: ["AubadeCore"])
    ],
    targets: [
        .target(name: "AubadeCore"),
        .testTarget(name: "AubadeCoreTests", dependencies: ["AubadeCore"]),
    ]
)
