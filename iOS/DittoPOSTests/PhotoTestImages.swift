import ImageIO
import UIKit
import UniformTypeIdentifiers

@MainActor enum PhotoTestImages {
    static var stockPhoto: Data {
        get throws {
            let url = Bundle(for: PhotoAttachmentsTests.self).url(forResource: "burger", withExtension: "png", subdirectory: "StarterImages")!
            return try Data(contentsOf: url)
        }
    }

    static let colors: [[UInt8]] = [[255, 0, 0], [0, 255, 0], [0, 0, 255], [255, 255, 0]]

    static func png(_ color: UIColor, width: Int = 32, height: Int = 32) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        return renderer.pngData { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    static func pattern(width: Int, height: Int, noise: Bool = false) -> CGImage {
        var seed: UInt32 = 42
        var bytes = [UInt8]()
        bytes.reserveCapacity(width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                if noise {
                    seed = seed &* 1664525 &+ 1013904223
                    bytes += [UInt8(truncatingIfNeeded: seed >> 24), UInt8(truncatingIfNeeded: seed >> 16), UInt8(truncatingIfNeeded: seed >> 8), 255]
                } else {
                    bytes += colors[(y < height / 2 ? 0 : 2) + (x < width / 2 ? 0 : 1)] + [255]
                }
            }
        }
        let provider = CGDataProvider(data: Data(bytes) as CFData)!
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
                       space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
    }

    static func encode(_ image: CGImage, type: UTType = .png, orientation: Int = 1) -> Data {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, type.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, image, [kCGImagePropertyOrientation: orientation, kCGImageDestinationLossyCompressionQuality: 1] as CFDictionary)
        precondition(CGImageDestinationFinalize(destination))
        return data as Data
    }

    static func rgb(_ image: CGImage, x: Int, y: Int) -> [UInt8] {
        let pixel = image.cropping(to: CGRect(x: x, y: y, width: 1, height: 1))!
        var bytes = [UInt8](repeating: 0, count: 4)
        bytes.withUnsafeMutableBytes { buffer in
            let context = CGContext(data: buffer.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            context.draw(pixel, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        return Array(bytes.prefix(3))
    }
}
