import Combine
import DittoSwift
import Foundation
import UIKit
import XCTest

@MainActor final class PhotoLoaderTests: XCTestCase {
    private let owner = DocumentID(id: "coffee", locationId: "A")
    private let a = PhotoReference(id: "A", len: 1, metadata: [:])
    private let b = PhotoReference(id: "B", len: 1, metadata: [:])

    func testReferenceAndOwnerChangesCancelAndRejectObsoleteCompletions() {
        let source = ControlledPhotos()
        let loader = PhotoLoader(cache: PhotoImageCache(), fetch: source.fetch)
        loader.update(a, owner: owner)
        loader.update(a, owner: owner)
        XCTAssertEqual(source.requests.count, 1)
        loader.update(b, owner: owner)
        XCTAssertEqual(source.canceled, [0])
        source.requests[1].complete(PhotoTestImages.png(.blue))
        let current = loader.image
        XCTAssertNotNil(current)
        XCTAssertNil(loader.image(matching: a))
        XCTAssertTrue(loader.image(matching: b) === current)
        source.requests[0].complete(PhotoTestImages.png(.red))
        XCTAssertTrue(loader.image === current)
        loader.update(nil, owner: owner)
        XCTAssertNil(loader.image)
        XCTAssertEqual(source.canceled, [0, 1])
        loader.update(a, owner: owner)
        loader.update(a, owner: DocumentID(id: owner.id, locationId: "B"))
        XCTAssertEqual(source.canceled, [0, 1, 2])
        source.requests[2].complete(PhotoTestImages.png(.red))
        XCTAssertNil(loader.image)
        loader.stop()
        source.requests[3].complete(PhotoTestImages.png(.red))
        XCTAssertNil(loader.image)
        XCTAssertEqual(source.canceled, [0, 1, 2, 3])
    }

    func testCachedImagesSurviveOfflineReuseAndCorruptDataUsesThePlaceholder() {
        let source = ControlledPhotos()
        let loader = PhotoLoader(cache: PhotoImageCache(), fetch: source.fetch)
        loader.update(a, owner: owner)
        source.requests[0].complete(PhotoTestImages.png(.red))
        let cached = loader.image
        loader.stop()
        loader.update(a, owner: DocumentID(id: "other", locationId: "B"))
        XCTAssertTrue(loader.image === cached)
        XCTAssertEqual(source.requests.count, 1)
        loader.update(b, owner: owner)
        XCTAssertNil(loader.image)
        source.requests[1].complete(Data("corrupt".utf8))
        XCTAssertNil(loader.image)
        source.requests[1].complete(nil)
        XCTAssertNil(loader.image)
        loader.update(a, owner: owner)
        XCTAssertTrue(loader.image === cached)
        loader.stop()
    }

    func testSDKFileAvailabilityUpdatesTheImageWithoutAnotherDocumentResultAndStopReleasesTheFetcher() async throws {
        try await TestDitto.withInstance { origin in
            let data = PhotoTestImages.png(.red)
            let attachment = try await PhotoAttachments.importPhoto(data, mimeType: "image/png", store: origin.store)
            let reference = PhotoAttachments.reference(to: attachment)
            try await TestDitto.withInstance { receiver in
                try await receive(reference, store: receiver.store)
                let loader = PhotoLoader(store: receiver.store)
                defer { loader.stop() }
                loader.update(reference, owner: owner)
                XCTAssertNil(loader.image)
                XCTAssertEqual(receiver.store.attachmentFetchers.count, 1)
                let ready = expectation(description: "File availability updates the current photo")
                let observation = loader.$image.compactMap { $0 }.prefix(1).sink { _ in ready.fulfill() }
                defer { observation.cancel() }
                let local = try await PhotoAttachments.importPhoto(data, mimeType: "image/png", store: receiver.store)
                XCTAssertEqual(local.id, attachment.id)
                await fulfillment(of: [ready], timeout: 5)
                XCTAssertNotNil(loader.image)
                loader.stop()
                XCTAssertTrue(receiver.store.attachmentFetchers.isEmpty)
                let missing = try await PhotoAttachments.importPhoto(PhotoTestImages.png(.blue), mimeType: "image/png", store: origin.store)
                let missingReference = PhotoAttachments.reference(to: missing)
                try await receive(missingReference, store: receiver.store)
                loader.update(missingReference, owner: owner)
                XCTAssertEqual(receiver.store.attachmentFetchers.count, 1)
                loader.stop()
                XCTAssertTrue(receiver.store.attachmentFetchers.isEmpty)
            }
        }
    }

    private func receive(_ reference: PhotoReference, store: DittoStore) async throws {
        // A received document introduces the token before its separately transferred file.
        try await store.execute(
            query: "INSERT INTO sale_items INITIAL DOCUMENTS (:document)",
            arguments: ["document": ["_id": ["id": owner.id, "locationId": owner.locationId]]]
        )
        try await store.execute(
            query: "UPDATE COLLECTION sale_items (image ATTACHMENT) SET image = :image WHERE _id.id = :id AND _id.locationId = :locationId",
            arguments: ["id": owner.id, "locationId": owner.locationId, "image": reference.token]
        )
    }
}

@MainActor private final class ControlledPhotos {
    struct Request {
        let reference: PhotoReference
        let complete: @MainActor @Sendable (Data?) -> Void
    }
    var requests: [Request] = []
    var canceled: [Int] = []

    func fetch(_ reference: PhotoReference, completion: @escaping @MainActor @Sendable (Data?) -> Void) -> () -> Void {
        let index = requests.count
        requests.append(Request(reference: reference, complete: completion))
        return { self.canceled.append(index) }
    }
}
