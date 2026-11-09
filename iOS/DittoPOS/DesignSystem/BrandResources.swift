import Foundation

enum BrandResources {
    static let bundle = Bundle(for: BundleToken.self)

    private final class BundleToken: NSObject {}
}
