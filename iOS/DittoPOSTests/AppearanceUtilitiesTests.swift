import UIKit
import XCTest
@testable import DittoPOS

final class AppearanceUtilitiesTests: XCTestCase {
    func testGrayAssetPreservesLightAndDarkColors() throws {
        let color = try XCTUnwrap(UIColor(named: "AppGray5", in: .main, compatibleWith: nil))
        for (style, expected) in [(UIUserInterfaceStyle.light, [229, 229, 234]), (.dark, [44, 44, 46])] {
            let resolved = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            XCTAssertTrue(resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
            for (actual, component) in zip([red, green, blue], expected) {
                XCTAssertEqual(actual, CGFloat(component) / 255, accuracy: 0.001)
            }
            XCTAssertEqual(alpha, 1, accuracy: 0.001)
        }
    }

    func testDeviceOrientationClassification() {
        for orientation in [UIDeviceOrientation.landscapeLeft, .landscapeRight] {
            XCTAssertTrue(orientation.isLandscape)
            XCTAssertFalse(orientation.isPortrait)
        }
        for orientation in [UIDeviceOrientation.portrait, .portraitUpsideDown] {
            XCTAssertTrue(orientation.isPortrait)
            XCTAssertFalse(orientation.isLandscape)
        }
        for orientation in [UIDeviceOrientation.unknown, .faceUp, .faceDown] {
            XCTAssertFalse(orientation.isLandscape)
            XCTAssertFalse(orientation.isPortrait)
        }
    }
}
