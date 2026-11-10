import Combine
import DittoSwift
import Foundation
import ImageIO
import UIKit

@MainActor final class PhotoImageCache {
    static let shared = PhotoImageCache()
    private let images = NSCache<NSString, UIImage>()

    init() {
        images.countLimit = 32
        images.totalCostLimit = 16 * 1024 * 1024
    }

    subscript(id: String) -> UIImage? {
        get { images.object(forKey: id as NSString) }
        set {
            if let image = newValue {
                let cost = (image.cgImage?.bytesPerRow ?? 0) * (image.cgImage?.height ?? 0)
                images.setObject(image, forKey: id as NSString, cost: cost)
            } else {
                images.removeObject(forKey: id as NSString)
            }
        }
    }
}

@MainActor final class PhotoLoader: ObservableObject {
    typealias Fetch = (PhotoReference, @escaping @MainActor @Sendable (Data?) -> Void) throws -> () -> Void
    @Published private(set) var image: UIImage?
    private var referenceID: String?
    private var owner: DocumentID?
    private var generation = 0
    private var cancelFetch: (() -> Void)?
    private let fetch: Fetch
    private let cache: PhotoImageCache

    init(cache: PhotoImageCache = .shared, fetch: @escaping Fetch) {
        self.cache = cache
        self.fetch = fetch
    }

    convenience init(store: DittoStore) {
        self.init { reference, completion in
            let fetcher = try store.fetchAttachment(token: reference.token, deliverOn: .global(qos: .userInitiated)) { event in
                switch event {
                case .completed(let attachment):
                    let data = try? attachment.data()
                    Task { @MainActor in completion(data) }
                case .deleted:
                    Task { @MainActor in completion(nil) }
                case .progress: break
                @unknown default: break
                }
            }
            // SDK auto-fetch transfers bytes; this retained handle drives this image's availability.
            // https://docs.ditto.live/sdk/latest/crud/working-with-attachments#fetching-attachments
            return { fetcher.stop() }
        }
    }

    func update(_ reference: PhotoReference?, owner: DocumentID) {
        guard self.owner != owner || referenceID != reference?.id else { return }
        stop()
        self.owner = owner
        referenceID = reference?.id
        guard let reference else { return }
        if let cached = cache[reference.id] {
            image = cached
            return
        }
        let request = generation
        do {
            cancelFetch = try fetch(reference) { [weak self] data in
                guard let self, self.generation == request else { return }
                self.image = data.flatMap(Self.decode)
                self.cache[reference.id] = self.image
            }
        } catch {
            image = nil
        }
    }

    func stop() {
        generation += 1
        cancelFetch?()
        cancelFetch = nil
        owner = nil
        referenceID = nil
        image = nil
    }

    func image(matching reference: PhotoReference?) -> UIImage? {
        referenceID == reference?.id ? image : nil
    }

    private static func decode(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 512
              ] as CFDictionary) else { return nil }
        return UIImage(cgImage: image)
    }
}
