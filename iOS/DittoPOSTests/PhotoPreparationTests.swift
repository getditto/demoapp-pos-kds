import Foundation
import UIKit
import UniformTypeIdentifiers
import XCTest

@MainActor final class PhotoPreparationTests: XCTestCase {
    func testCropCoordinatesMatchSharedPanZoomAndBoundaryCases() throws {
        struct CropCase: Decodable {
            let name: String
            let width: Int
            let height: Int
            let centerX: Double
            let centerY: Double
            let zoom: Double
            let left: Int
            let top: Int
            let side: Int
        }
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "photo-crops", withExtension: "json", subdirectory: "Fixtures"))
        let cases = try JSONDecoder().decode([CropCase].self, from: Data(contentsOf: url))
        for item in cases {
            let rect = try SquarePhotoCrop(centerX: item.centerX, centerY: item.centerY, zoom: item.zoom).rectangle(width: item.width, height: item.height)
            XCTAssertEqual(rect, CGRect(x: item.left, y: item.top, width: item.side, height: item.side), item.name)
        }
        for crop in [SquarePhotoCrop(zoom: 0.5), SquarePhotoCrop(centerX: .nan), SquarePhotoCrop(centerY: .infinity), SquarePhotoCrop(zoom: 1000)] {
            XCTAssertThrowsError(try crop.rectangle(width: 32, height: 48))
        }
        XCTAssertThrowsError(try SquarePhotoCrop().rectangle(width: 0, height: 32))
    }

    func testPreparationNormalizesAllExifRotationsAndMirrorsBeforeCropping() throws {
        let expected = [[0, 1, 2, 3], [1, 0, 3, 2], [3, 2, 1, 0], [2, 3, 0, 1],
                        [0, 2, 1, 3], [2, 0, 3, 1], [3, 1, 2, 0], [1, 3, 0, 2]]
        let source = PhotoTestImages.pattern(width: 120, height: 80)
        for orientation in 1...8 {
            let data = PhotoTestImages.encode(source, type: .jpeg, orientation: orientation)
            let prepared = try PhotoPreparation.prepare(data)
            let image = try XCTUnwrap(UIImage(data: prepared.data)?.cgImage)
            XCTAssertEqual(image.width, 80)
            XCTAssertEqual(image.height, 80)
            for (index, point) in [(20, 20), (60, 20), (20, 60), (60, 60)].enumerated() {
                let pixel = PhotoTestImages.rgb(image, x: point.0, y: point.1)
                for channel in 0..<3 {
                    XCTAssertLessThan(abs(Int(pixel[channel]) - Int(PhotoTestImages.colors[expected[orientation - 1][index]][channel])), 25, "orientation \(orientation), quadrant \(index)")
                }
            }
        }
    }

    func testPreparationPreservesDetailInTheChosenCropAndBoundsExportSize() throws {
        let source = PhotoTestImages.encode(PhotoTestImages.pattern(width: 120, height: 80))
        let corner = try PhotoPreparation.prepare(source, crop: SquarePhotoCrop(centerX: 0, centerY: 0, zoom: 2))
        let image = try XCTUnwrap(UIImage(data: corner.data)?.cgImage)
        XCTAssertEqual(image.width, 40)
        let pixel = PhotoTestImages.rgb(image, x: 20, y: 20)
        XCTAssertGreaterThan(pixel[0], 230)
        XCTAssertLessThan(pixel[1], 25)
        XCTAssertLessThan(pixel[2], 25)

        for (width, height, noise, expectedSize) in [(2048, 1024, false, 512), (48, 30, false, 30), (512, 512, true, 512)] {
            let data = PhotoTestImages.encode(PhotoTestImages.pattern(width: width, height: height, noise: noise))
            let result = try PhotoPreparation.prepare(data)
            let decoded = try XCTUnwrap(UIImage(data: result.data)?.cgImage)
            XCTAssertEqual(decoded.width, expectedSize)
            XCTAssertEqual(decoded.height, expectedSize)
            XCTAssertEqual(result.pixelSize, expectedSize)
            XCTAssertLessThanOrEqual(result.data.count, 200 * 1024)
            XCTAssertEqual(result.data.prefix(2), Data([0xFF, 0xD8]))
        }
        XCTAssertThrowsError(try PhotoPreparation.prepare(Data("invalid image".utf8)))
    }
}
