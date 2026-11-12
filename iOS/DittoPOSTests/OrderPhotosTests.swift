import Combine
import DittoSwift
import SwiftUI
import UIKit
import XCTest

@MainActor final class OrderPhotosTests: XCTestCase {
    func testQuantityChangesKeepCapturedDetailsAndRemovalThenReaddCapturesCurrentCatalog() async throws {
        try await TestDitto.withInstance { ditto in
            let catalog = SaleItemsRepository(ditto: ditto, locationPublisher: Just(nil).eraseToAnyPublisher())
            let id = DocumentID(id: "coffee", locationId: "A")
            let metadata = SaleItemMetadata(documentId: id, name: "Original", imageName: "coffee", price: Price(cents: 199))
            try await catalog.create(SaleItemCreation(metadata: metadata, initialQuantity: 2))
            let a = try await PhotoAttachments.importPhoto(PhotoTestImages.png(.red), mimeType: "image/png", store: ditto.store)
            let b = try await PhotoAttachments.importPhoto(PhotoTestImages.png(.blue), mimeType: "image/png", store: ditto.store)
            let withoutPhoto = CartLineItem(from: try await sale(id, store: ditto.store), qty: 1)
            try await PhotoAttachments.replace(a, for: id, executor: ditto.store)
            let captured = CartLineItem(from: try await sale(id, store: ditto.store), qty: 1)
            var order = Order.new(locationId: "A").addingCartLineItem(captured, lineItemId: "line`photo")
                .addingCartLineItem(withoutPhoto, lineItemId: "no-photo")
            try await OrderCommands.upsert(order, store: ditto.store)
            let saved = try await read(order.documentId, store: ditto.store)
            XCTAssertEqual(saved.cart["line`photo"]?.image, captured.image)
            XCTAssertNil(saved.cart["no-photo"]?.image)
            order = saved

            try await catalog.updateMetadata(SaleItemMetadata(documentId: id, name: "Renamed", imageName: "milk", price: Price(cents: 250)))
            try await PhotoAttachments.replace(b, for: id, executor: ditto.store)
            try await catalog.increment(-4, id: id)
            let current = try await sale(id, store: ditto.store)
            order = order.addingCartLineItem(CartLineItem(from: current, qty: 3), lineItemId: "line`photo")
                .addingCartLineItem(CartLineItem(from: current, qty: 2), lineItemId: "no-photo")
            try await OrderCommands.upsert(order, store: ditto.store)
            let edited = try await read(order.documentId, store: ditto.store)
            var expected = try XCTUnwrap(saved.cart["line`photo"])
            expected.qty = 3
            XCTAssertEqual(edited.cart["line`photo"], expected)
            XCTAssertNil(edited.cart["no-photo"]?.image)
            XCTAssertEqual(edited.cart["no-photo"]?.name, "Original")
            XCTAssertEqual(current.quantity, -2)

            try await OrderCommands.clearCart(of: edited, executor: ditto.store)
            let removed = try await read(order.documentId, store: ditto.store)
            XCTAssertNil(removed.cart["line`photo"])
            let readded = CartLineItem(from: current, qty: 1)
            order = removed.addingCartLineItem(readded, lineItemId: "line`photo")
            try await OrderCommands.upsert(order, store: ditto.store)
            let savedReadd = try await read(order.documentId, store: ditto.store)
            XCTAssertEqual(savedReadd.cart["line`photo"]?.name, readded.name)
            XCTAssertEqual(savedReadd.cart["line`photo"]?.price, readded.price)
            XCTAssertEqual(savedReadd.cart["line`photo"]?.image, readded.image)
            XCTAssertEqual(savedReadd.cart["line`photo"].map { DittoWireDate.string(from: $0.createdAt) }, DittoWireDate.string(from: readded.createdAt))
            XCTAssertEqual(readded.image, PhotoAttachments.reference(to: b))
        }
    }

    func testPaymentAndStatusPatchesPreserveOtherMapsPhotosAndLocationAndClearRemovesLines() async throws {
        try await TestDitto.withInstance { ditto in
            var order = try OrderFixture.load()
            let data = try PhotoTestImages.stockPhoto
            let attachment = try await PhotoAttachments.importPhoto(data, mimeType: "image/png", store: ditto.store)
            let old = try XCTUnwrap(order.cart.values.first)
            let line = CartLineItem(saleItemId: old.saleItemId, name: old.name, imageName: old.imageName, price: old.price, qty: old.qty, createdAt: old.createdAt, image: PhotoAttachments.reference(to: attachment))
            order.cart = ["line`photo": line]
            let other = Order(documentId: DocumentID(id: order.documentId.id, locationId: "B"), cart: order.cart, payments: order.payments, statusLog: order.statusLog, createdAt: order.createdAt)
            try await OrderCommands.upsert(order, store: ditto.store)
            try await OrderCommands.upsert(other, store: ditto.store)
            let catalog = SaleItemsRepository(ditto: ditto, locationPublisher: Just(nil).eraseToAnyPublisher())
            let saleID = DocumentID(id: line.saleItemId, locationId: order.documentId.locationId)
            try await catalog.create(SaleItemCreation(metadata: SaleItemMetadata(documentId: saleID, name: line.name, imageName: "coffee", price: line.price), initialQuantity: 1))
            try await PhotoAttachments.replace(attachment, for: saleID, executor: ditto.store)
            let payment = Payment(type: .cash, amount: order.total, createdAt: order.createdAt)
            let date = order.createdAt.addingTimeInterval(100)
            try await OrderCommands.addPayment(payment, paymentId: "payment`new", to: order.documentId, executor: ditto.store)
            try await OrderCommands.updateStatus(.processed, of: order.documentId, at: date, executor: ditto.store)
            let paid = try await read(order.documentId, store: ditto.store)
            XCTAssertEqual(paid, order.addingPayment(payment, paymentId: "payment`new").appendingStatus(.processed, at: date))
            let unchanged = try await read(other.documentId, store: ditto.store)
            XCTAssertEqual(unchanged, other)
            try await ditto.store.execute(query: "DELETE FROM sale_items WHERE _id.id = :id AND _id.locationId = :locationId", arguments: ["id": saleID.id, "locationId": saleID.locationId])
            let historical = try await read(order.documentId, store: ditto.store)
            XCTAssertEqual(historical, paid)
            // Historical lines render from their own references without a catalog document.
            let loader = PhotoLoader(store: ditto.store)
            defer { loader.stop() }
            let loaded = expectation(description: "The frozen receipt image is available")
            let observation = loader.$image.compactMap { $0 }.prefix(1).sink { _ in loaded.fulfill() }
            defer { observation.cancel() }
            loader.update(paid.cart["line`photo"]?.image, owner: paid.documentId)
            await fulfillment(of: [loaded], timeout: 5)
            XCTAssertEqual(try attachment.data(), data)
            let repository = OrdersRepository(ditto: ditto, locationPublisher: Just(nil).eraseToAnyPublisher())
            let cleared = expectation(description: "The cart is cleared")
            let orders = repository.observeOrder(order.documentId).compactMap { $0 }.filter { $0.cart.isEmpty }.prefix(1).sink { value in
                XCTAssertEqual(value.payments, paid.payments)
                XCTAssertEqual(value.statusLog, paid.statusLog)
                cleared.fulfill()
            }
            defer { orders.cancel() }
            repository.clearCart(of: paid)
            await fulfillment(of: [cleared], timeout: 5)
            let unchangedAfterClear = try await read(other.documentId, store: ditto.store)
            XCTAssertEqual(unchangedAfterClear, other)
            XCTAssertEqual(try attachment.data(), data)
        }
    }

    func testCaptureDoesNotRequireFileAndLaterAvailabilityLoadsTheFrozenReference() async throws {
        try await TestDitto.withInstance { origin in
            let data = PhotoTestImages.png(.red, width: 31, height: 31)
            let attachment = try await PhotoAttachments.importPhoto(data, mimeType: "image/png", store: origin.store)
            let reference = PhotoAttachments.reference(to: attachment)
            try await TestDitto.withInstance { receiver in
                let line = CartLineItem(saleItemId: "coffee", name: "Coffee", price: Price(cents: 199), image: reference)
                let order = Order.new(locationId: "A").addingCartLineItem(line, lineItemId: "line")
                try await OrderCommands.upsert(order, store: receiver.store)
                let received = try await read(order.documentId, store: receiver.store)
                XCTAssertEqual(received.cart["line"]?.image, reference)
                XCTAssertNil(received.cart["line"]?.imageName)
                XCTAssertFalse(try order.dittoJSONString().contains("imageName"))
                XCTAssertTrue(receiver.store.attachmentFetchers.isEmpty)
                let loader = PhotoLoader(store: receiver.store)
                defer { loader.stop() }
                loader.update(received.cart["line"]?.image, owner: received.documentId)
                XCTAssertNil(loader.image)
                let loaded = expectation(description: "The independently arriving file loads")
                let observation = loader.$image.compactMap { $0 }.prefix(1).sink { _ in loaded.fulfill() }
                defer { observation.cancel() }
                let local = try await PhotoAttachments.importPhoto(data, mimeType: "image/png", store: receiver.store)
                XCTAssertEqual(local.id, reference.id)
                await fulfillment(of: [loaded], timeout: 5)
                let afterFile = try await read(order.documentId, store: receiver.store)
                XCTAssertEqual(afterFile, received)
            }
        }
    }

    func testOrderPhotoRendersRecordedImageAfterCatalogReplacement() async throws {
        try await TestDitto.withInstance { ditto in
            let id = DocumentID(id: "coffee", locationId: "A")
            let catalog = SaleItemsRepository(ditto: ditto, locationPublisher: Just(nil).eraseToAnyPublisher())
            try await catalog.create(SaleItemCreation(metadata: SaleItemMetadata(documentId: id, name: "Coffee", imageName: "coffee", price: Price(cents: 199)), initialQuantity: 1))
            let red = try await PhotoAttachments.importPhoto(PhotoTestImages.png(.red, width: 63, height: 63), mimeType: "image/png", store: ditto.store)
            try await PhotoAttachments.replace(red, for: id, executor: ditto.store)
            let order = Order.new(locationId: "A").addingCartLineItem(CartLineItem(from: try await sale(id, store: ditto.store)), lineItemId: "line")
            try await OrderCommands.upsert(order, store: ditto.store)
            let blue = try await PhotoAttachments.importPhoto(PhotoTestImages.png(.blue), mimeType: "image/png", store: ditto.store)
            try await PhotoAttachments.replace(blue, for: id, executor: ditto.store)
            let recorded = try await read(order.documentId, store: ditto.store)
            let line = try XCTUnwrap(recorded.cart["line"])
            let host = UIHostingController(rootView: OrderLinePhotoView(line: line, orderID: recorded.documentId, store: ditto.store).frame(width: 56, height: 56))
            let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
            let root = try XCTUnwrap(scene.windows.first { $0.isKeyWindow }?.rootViewController)
            root.addChild(host)
            host.view.frame = CGRect(x: 0, y: 0, width: 56, height: 56)
            root.view.addSubview(host.view)
            host.didMove(toParent: root)
            defer {
                host.willMove(toParent: nil)
                host.view.removeFromSuperview()
                host.removeFromParent()
            }
            let deadline = Date().addingTimeInterval(5)
            var pixel: [UInt8] = []
            repeat {
                host.view.setNeedsLayout()
                host.view.layoutIfNeeded()
                let image = UIGraphicsImageRenderer(size: host.view.bounds.size).image { _ in host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true) }
                pixel = PhotoTestImages.rgb(try XCTUnwrap(image.cgImage), x: image.cgImage!.width / 2, y: image.cgImage!.height / 2)
                if pixel[0] > 240 && pixel[1] < 15 && pixel[2] < 15 { break }
                try await Task.sleep(for: .milliseconds(10))
            } while Date() < deadline
            XCTAssertEqual(pixel, [255, 0, 0], "The receipt must render its recorded photo, not the blue catalog photo or legacy asset")
        }
    }

    private func read(_ id: DocumentID, store: DittoStore) async throws -> Order {
        let result = try await store.execute(query: "SELECT * FROM pos_orders WHERE _id.id = :id AND _id.locationId = :locationId", arguments: ["id": id.id, "locationId": id.locationId])
        let orders: [Order] = try result.decode()
        return try XCTUnwrap(orders.first)
    }

    private func sale(_ id: DocumentID, store: DittoStore) async throws -> SaleItem {
        let result = try await store.execute(query: "SELECT * FROM sale_items WHERE _id.id = :id AND _id.locationId = :locationId", arguments: ["id": id.id, "locationId": id.locationId])
        let items: [SaleItem] = try result.decode()
        return try XCTUnwrap(items.first)
    }
}
