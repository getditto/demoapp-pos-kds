// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DittoUI",
    platforms: [.iOS(.v16)],
    products: [.library(name: "DittoUI", targets: ["DittoUI"])],
    targets: [.target(name: "DittoUI", resources: [.process("BrandIcons.xcassets"), .copy("BrandResources")])]
)
