import Combine
import DittoSwift
import Foundation
import UIKit
import XCTest

@MainActor final class PhotoAttachmentsTests: XCTestCase {
    func testOptionalPhotosPreserveStockMetadataAndLocationIdentity() async throws {
        try await TestDitto.withInstance { ditto in
            let id = DocumentID(id: "coffee'冰", locationId: "A")
            let other = DocumentID(id: id.id, locationId: "B")
            let repository = SaleItemsRepository(ditto: ditto, locationPublisher: Just(nil).eraseToAnyPublisher())
            let metadata = SaleItemMetadata(documentId: id, name: "Coffee", price: Price(cents: 199))
            try await repository.create(SaleItemCreation(metadata: metadata, initialQuantity: 2))
            try await repository.create(SaleItemCreation(metadata: SaleItemMetadata(documentId: other, name: "Other", price: Price(cents: 250)), initialQuantity: 7))
            try await repository.increment(-4, id: id)
            try await PhotoAttachments.configure(store: ditto.store)
            let configuration = try await ditto.store.execute(query: "SHOW attachments_auto_fetch")
            XCTAssertEqual(configuration.items.first?.value["attachments_auto_fetch"] as? Bool, true)

            let aData = try PhotoTestImages.stockPhoto
            let a = try await PhotoAttachments.importPhoto(aData, mimeType: "image/png", store: ditto.store)
            let b = try await PhotoAttachments.importPhoto(PhotoTestImages.png(.blue), mimeType: "image/png", store: ditto.store)
            let observedReplacement = expectation(description: "The active catalog observer receives the replacement photo")
            let observation = repository.observeLocationSaleItems(id.locationId)
                .filter { $0.first(where: { $0.documentId == id })?.image?.id == b.id }
                .prefix(1)
                .sink { items in
                    XCTAssertEqual(items.first(where: { $0.documentId == id })?.quantity, -2)
                    observedReplacement.fulfill()
                }
            defer { observation.cancel() }
            try await PhotoAttachments.replace(a, for: id, executor: ditto.store)
            let photo = try await read(id, store: ditto.store)
            XCTAssertEqual(photo.image, PhotoAttachments.reference(to: a))
            XCTAssertEqual(try a.data(), aData)
            XCTAssertEqual(photo.metadata, metadata)
            XCTAssertEqual(photo.quantity, -2)
            let foreign = try await read(other, store: ditto.store)
            XCTAssertNil(foreign.image)
            XCTAssertEqual(foreign.quantity, 7)

            let renamed = SaleItemMetadata(documentId: id, name: "Renamed", price: Price(cents: 0))
            try await repository.updateMetadata(renamed)
            let updated = try await read(id, store: ditto.store)
            XCTAssertEqual(updated.image, photo.image)
            XCTAssertEqual(updated.quantity, -2)
            try await PhotoAttachments.replace(b, for: id, executor: ditto.store)
            await fulfillment(of: [observedReplacement], timeout: 5)
            let replaced = try await read(id, store: ditto.store)
            XCTAssertEqual(replaced.image, PhotoAttachments.reference(to: b))
            XCTAssertNotEqual(replaced.image?.id, photo.image?.id)
            try await PhotoAttachments.remove(for: id, executor: ditto.store)
            let removed = try await read(id, store: ditto.store)
            XCTAssertNil(removed.image)
            XCTAssertEqual(removed.metadata, renamed)
            XCTAssertEqual(removed.quantity, -2)
            let absent = try await ditto.store.execute(query: "SELECT image FROM sale_items WHERE _id.id = :id AND _id.locationId = :locationId", arguments: ["id": id.id, "locationId": id.locationId])
            XCTAssertNil(absent.items.first?.value["image"])
        }
    }

    private func read(_ id: DocumentID, store: DittoStore) async throws -> SaleItem {
        let result = try await store.execute(query: "SELECT * FROM COLLECTION sale_items (image ATTACHMENT) WHERE _id.id = :id AND _id.locationId = :locationId", arguments: ["id": id.id, "locationId": id.locationId])
        let items: [SaleItem] = result.decodeOrSkip()
        return try XCTUnwrap(items.first)
    }
}
