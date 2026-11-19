// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AppUI",
    platforms: [.iOS(.v16)],
    products: [.library(name: "AppUI", targets: ["AppUI"])],
    targets: [.target(name: "AppUI", resources: [.process("BrandIcons.xcassets"), .copy("BrandResources")])]
)
