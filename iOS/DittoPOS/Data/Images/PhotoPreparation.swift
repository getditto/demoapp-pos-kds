import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct SquarePhotoCrop: Codable, Equatable, Sendable {
    var centerX: Double = 0.5
    var centerY: Double = 0.5
    var zoom: Double = 1

    func rectangle(width: Int, height: Int) throws -> CGRect {
        guard width > 0, height > 0, centerX.isFinite, centerY.isFinite, zoom.isFinite, zoom >= 1 else {
            throw PhotoPreparation.Failure.invalidCrop
        }
        let side = floor(Double(min(width, height)) / zoom)
        guard side >= 1 else { throw PhotoPreparation.Failure.invalidCrop }
        let x = floor(min(max(centerX * Double(width) - side / 2, 0), Double(width) - side))
        let y = floor(min(max(centerY * Double(height) - side / 2, 0), Double(height) - side))
        return CGRect(x: x, y: y, width: side, height: side)
    }
}

struct PreparedPhoto: Sendable {
    let data: Data
    let pixelSize: Int
    let mimeType = "image/jpeg"
}

enum PhotoPreparation {
    enum Failure: Error { case unreadableImage, invalidCrop, encodingFailed, imageTooLarge }

    static func prepare(_ data: Data, crop: SquarePhotoCrop = SquarePhotoCrop()) throws -> PreparedPhoto {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            throw Failure.unreadableImage
        }
        _ = try crop.rectangle(width: width, height: height)
        let requiredScale = min(1, 512 * crop.zoom / Double(min(width, height)))
        let maxDimension = max(1, Int(ceil(Double(max(width, height)) * requiredScale)))
        // ImageIO applies EXIF rotation and mirroring before the crop's oriented coordinates.
        // https://developer.apple.com/documentation/imageio/kcgimagesourcecreatethumbnailwithtransform
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]
        guard let oriented = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
              let square = oriented.cropping(to: try crop.rectangle(width: oriented.width, height: oriented.height)) else {
            throw Failure.unreadableImage
        }
        let size = min(512, square.width)
        guard let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
            throw Failure.encodingFailed
        }
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: size, height: size))
        context.interpolationQuality = .high
        context.draw(square, in: CGRect(x: 0, y: 0, width: size, height: size))
        guard let image = context.makeImage() else { throw Failure.encodingFailed }
        for quality in stride(from: 0.9, through: 0.1, by: -0.05) {
            let output = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else {
                throw Failure.encodingFailed
            }
            CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
            guard CGImageDestinationFinalize(destination) else { throw Failure.encodingFailed }
            if output.length <= 200 * 1024 { return PreparedPhoto(data: output as Data, pixelSize: size) }
        }
        throw Failure.imageTooLarge
    }
}
