// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DecisionPicker",
    platforms: [
        .iOS(.v17) 
    ],
    products: [
        .library(
            name: "DecisionPicker",
            targets: ["DecisionPicker"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "DecisionPicker",
            dependencies: [],
            path: "Sources/DecisionPicker"),
        .testTarget(
            name: "DecisionPickerTests",
            dependencies: ["DecisionPicker"],
            path: "Tests/DecisionPickerTests"),
    ]
)
