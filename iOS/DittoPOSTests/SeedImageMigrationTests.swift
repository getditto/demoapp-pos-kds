import Combine
import DittoSwift
import UIKit
import XCTest

@MainActor final class SeedImageMigrationTests: XCTestCase {
    func testBootstrapImportsEveryBundledPhotoAndPreservesTheLegacyInitialContractInEitherOrder() async throws {
        for oldFirst in [true, false] {
            try await TestDitto.withInstance { ditto in
                let old = LegacyDemoSeeder(store: ditto.store)
                let current = DemoSeeder(store: ditto.store)
                if oldFirst { await old.seedAll() }
                await current.seedAll()
                await old.seedAll()
                await current.seedAll()
                let result = try await ditto.store.execute(query: "SELECT * FROM sale_items")
                let items: [SaleItem] = try result.decode()
                let legacy = LegacySaleItemSeed.saleItemsForAllLocations()
                XCTAssertEqual(Set(items.map(\.documentId)), Set(legacy.map(\.documentId)))
                for expected in legacy {
                    let item = try XCTUnwrap(items.first { $0.documentId == expected.documentId })
                    XCTAssertEqual(item.metadata, SaleItemMetadata(documentId: expected.documentId, name: expected.name, price: expected.price))
                    XCTAssertEqual(item.quantity, 20)
                    // This independent fixture mapping checks the production ID-to-file mapping.
                    let file = expected.imageName.replacingOccurrences(of: "_", with: "-")
                    let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: file, withExtension: "png", subdirectory: "StarterImages"))
                    let bytes = try Data(contentsOf: url)
                    let attachment = try await PhotoAttachments.importPhoto(bytes, mimeType: "image/png", store: ditto.store)
                    XCTAssertEqual(item.image, PhotoAttachments.reference(to: attachment), expected.name)
                    XCTAssertEqual(try attachment.data(), bytes)
                }
                let leftovers = try await ditto.store.execute(query: "SELECT * FROM sale_items WHERE imageName IS NOT MISSING")
                XCTAssertTrue(leftovers.items.isEmpty)
            }
        }
    }

    func testCatalogMigrationUsesIdentityAndPreservesEditsReplacementRemovalAndUnknownItems() async throws {
        try await TestDitto.withInstance { ditto in
            await LegacyDemoSeeder(store: ditto.store).seedAll()
            let id = DocumentID(id: "00001", locationId: "00001")
            let existing = DocumentID(id: "00008", locationId: "00001")
            let deleted = DocumentID(id: "00013", locationId: "00001")
            let custom = DocumentID(id: "custom", locationId: "00001")
            let foreign = DocumentID(id: id.id, locationId: "00002")
            let customPhoto = try await PhotoAttachments.importPhoto(PhotoTestImages.png(.blue), mimeType: "image/png", store: ditto.store)
            try await PhotoAttachments.replace(customPhoto, for: existing, executor: ditto.store)
            try await ditto.store.execute(query: "UPDATE sale_items SET name = 'Edited', imageName = 'milk' WHERE _id.id = :id AND _id.locationId = :locationId", arguments: ["id": id.id, "locationId": id.locationId])
            try await SaleItemCommands.restart(0, id: id, store: ditto.store)
            try await SaleItemCommands.increment(-2, id: id, store: ditto.store)
            try await ditto.store.execute(query: "DELETE FROM sale_items WHERE _id.id = :id AND _id.locationId = :locationId", arguments: ["id": deleted.id, "locationId": deleted.locationId])
            for target in [custom, foreign] {
                let item = LegacySaleItem.seed(id: target.id, locationId: target.locationId, name: "Custom", imageName: "burger", cents: 0)
                try await ditto.store.execute(query: "INSERT INTO sale_items DOCUMENTS (deserialize_json(:json))", arguments: ["json": try item.dittoJSONString()])
            }
            await DemoSeeder(store: ditto.store).seedAll()
            let prepared = try await catalog(id, store: ditto.store)
            XCTAssertEqual(prepared.name, "Edited")
            XCTAssertEqual(prepared.quantity, -2)
            let burger = try await PhotoAttachments.importPhoto(PhotoTestImages.stockPhoto, mimeType: "image/png", store: ditto.store)
            XCTAssertEqual(prepared.image?.id, burger.id)
            let retained = try await catalog(existing, store: ditto.store)
            XCTAssertEqual(retained.image?.id, customPhoto.id)
            for target in [custom, foreign] {
                let item = try await catalog(target, store: ditto.store)
                XCTAssertNil(item.image)
                XCTAssertNil(item.quantity)
            }
            try await PhotoAttachments.remove(for: id, executor: ditto.store)
            await DemoSeeder(store: ditto.store).seedAll()
            await LegacyDemoSeeder(store: ditto.store).seedAll()
            let removed = try await catalog(id, store: ditto.store)
            XCTAssertNil(removed.image)
            XCTAssertEqual(removed.quantity, -2)
            let absent = try await ditto.store.execute(query: "SELECT * FROM sale_items WHERE _id.id = :id AND _id.locationId = :locationId", arguments: ["id": deleted.id, "locationId": deleted.locationId])
            XCTAssertTrue(absent.items.isEmpty)
        }
    }

    func testOrderImagesPrepareBeforeStartupOrOnLateObservationWithoutConsultingTheCatalog() async throws {
        for beforeStartup in [true, false] {
            try await TestDitto.withInstance { ditto in
                let id = DocumentID(id: "receipt'冰", locationId: "00001")
                let foreignID = DocumentID(id: id.id, locationId: "00002")
                let line = CartLineItem(saleItemId: "00001", name: "Historical burger", price: Price(cents: 100), qty: 3, createdAt: Date(timeIntervalSince1970: 1_775_044_800))
                let order = Order(documentId: id, cart: ["line`photo": line, "preserved": line, "unknown": CartLineItem(saleItemId: "custom", name: "Custom", price: Price(cents: 0))], payments: ["cash": Payment(type: .cash, amount: Price(cents: 300), createdAt: line.createdAt)], statusLog: ["2026-04-01T00:00:00.000Z": "processed"], createdAt: line.createdAt)
                let foreign = Order(documentId: foreignID, cart: order.cart, payments: order.payments, statusLog: order.statusLog, createdAt: order.createdAt)
                let preservedPhoto = try await PhotoAttachments.importPhoto(PhotoTestImages.png(.blue), mimeType: "image/png", store: ditto.store)
                if beforeStartup {
                    try await LegacyOrderWriter.insert(order, imageName: "milk", store: ditto.store)
                    try await LegacyOrderWriter.insert(foreign, imageName: "milk", store: ditto.store)
                    try await PhotoAttachments.copy(PhotoAttachments.reference(to: preservedPhoto), to: id, lineItemId: "preserved", executor: ditto.store)
                }
                await DemoSeeder(store: ditto.store).seedAll()
                // A historical receipt must not require a surviving catalog item.
                try await ditto.store.execute(query: "DELETE FROM sale_items WHERE _id.id = :id AND _id.locationId = :locationId", arguments: ["id": "00001", "locationId": id.locationId])
                if beforeStartup {
                    let migrated = try await ditto.store.execute(query: "SELECT * FROM pos_orders WHERE _id.id = :id AND _id.locationId = :locationId", arguments: ["id": id.id, "locationId": id.locationId])
                    let values: [Order] = try migrated.decode()
                    XCTAssertNotNil(values.first?.cart["line`photo"]?.image)
                }
                let orders = OrdersRepository(ditto: ditto, locationPublisher: Just(nil).eraseToAnyPublisher())
                let selected = CurrentValueSubject<Order?, Never>(nil)
                let location = CurrentValueSubject<[Order], Never>([])
                let observers = [orders.observeOrder(id).sink { selected.send($0) }, orders.observeLocationOrders(id.locationId).sink { location.send($0) }]
                defer { observers.forEach { $0.cancel() } }
                if !beforeStartup {
                    try await LegacyOrderWriter.insert(order, imageName: "milk", store: ditto.store)
                    try await LegacyOrderWriter.insert(foreign, imageName: "milk", store: ditto.store)
                    try await PhotoAttachments.copy(PhotoAttachments.reference(to: preservedPhoto), to: id, lineItemId: "preserved", executor: ditto.store)
                }
                let received = expectation(description: "Both order consumers receive a prepared image")
                let deliveries = Publishers.CombineLatest(selected, location)
                    .filter { $0?.cart["line`photo"]?.image != nil && $1.first?.cart["line`photo"]?.image != nil }
                    .prefix(1).sink { _, _ in received.fulfill() }
                defer { deliveries.cancel() }
                await fulfillment(of: [received], timeout: 5)
                let prepared = try XCTUnwrap(selected.value)
                XCTAssertEqual(location.value.map(\.documentId), [id])
                XCTAssertEqual(prepared.cart["line`photo"]?.name, line.name)
                XCTAssertEqual(prepared.cart["line`photo"]?.price, line.price)
                XCTAssertEqual(prepared.cart["line`photo"]?.qty, line.qty)
                XCTAssertEqual(prepared.cart["line`photo"]?.createdAt, line.createdAt)
                XCTAssertEqual(prepared.payments, order.payments)
                XCTAssertEqual(prepared.statusLog, order.statusLog)
                XCTAssertEqual(prepared.createdAt, order.createdAt)
                XCTAssertNil(prepared.cart["unknown"]?.image)
                let current = try await ditto.store.execute(query: "SELECT * FROM pos_orders WHERE _id.id = :id AND _id.locationId = :locationId", arguments: ["id": id.id, "locationId": id.locationId])
                let currentOrders: [Order] = try current.decode()
                XCTAssertEqual(currentOrders.first?.cart["preserved"]?.image?.id, preservedPhoto.id)
                let original = try await PhotoAttachments.importPhoto(PhotoTestImages.stockPhoto, mimeType: "image/png", store: ditto.store)
                XCTAssertEqual(prepared.cart["line`photo"]?.image?.id, original.id)
                let raw = try await ditto.store.execute(query: "SELECT * FROM pos_orders WHERE _id.id = :id AND _id.locationId = :locationId", arguments: ["id": id.id, "locationId": id.locationId])
                XCTAssertFalse(String(decoding: try XCTUnwrap(raw.items.first).jsonData(), as: UTF8.self).contains("imageName"))
                var replay = order
                replay.cart = ["line`photo": line]
                try await LegacyOrderWriter.insert(replay, imageName: "milk", store: ditto.store)
                let replayed = try await SeedImageMigration.prepareOrders([prepared], store: ditto.store)
                let replayedOrder = try XCTUnwrap(replayed.first)
                XCTAssertEqual(replayedOrder.cart["line`photo"]?.image, prepared.cart["line`photo"]?.image)
                XCTAssertEqual(replayedOrder.cart["preserved"]?.image?.id, preservedPhoto.id)
                XCTAssertEqual(replayedOrder.payments, prepared.payments)
                XCTAssertEqual(replayedOrder.statusLog, prepared.statusLog)
                let foreignResult = try await ditto.store.execute(query: "SELECT * FROM pos_orders WHERE _id.id = :id AND _id.locationId = :locationId", arguments: ["id": foreignID.id, "locationId": foreignID.locationId])
                let foreignOrders: [Order] = try foreignResult.decode()
                XCTAssertNil(foreignOrders.first?.cart["line`photo"]?.image)
                for observer in observers { observer.cancel() }
                XCTAssertTrue(ditto.store.observers.isEmpty)
            }
        }
    }

    private func catalog(_ id: DocumentID, store: DittoStore) async throws -> SaleItem {
        let result = try await store.execute(query: "SELECT * FROM sale_items WHERE _id.id = :id AND _id.locationId = :locationId", arguments: ["id": id.id, "locationId": id.locationId])
        let items: [SaleItem] = try result.decode()
        return try XCTUnwrap(items.first)
    }

}
