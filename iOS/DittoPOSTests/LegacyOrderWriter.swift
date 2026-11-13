import DittoSwift
import Foundation

// Freeze beab457's wire fields and write path independently of the new encoders.
@MainActor enum LegacyOrderWriter {
    private struct Line: Encodable {
        let saleItemId: String
        let name: String
        let imageName: String
        let price: Price
        let qty: Int
        let createdAt: Date
    }

    private struct Document: Encodable {
        let documentId: DocumentID
        let cart: [String: Line]
        let payments: [String: Payment]
        let statusLog: [String: String]
        let createdAt: Date
        enum CodingKeys: String, CodingKey {
            case documentId = "_id"
            case cart, payments, createdAt
            case statusLog = "status_log"
        }
    }

    static func insert(_ order: Order, imageName: String, store: DittoStore) async throws {
        let document = Document(documentId: order.documentId, cart: order.cart.mapValues {
            Line(saleItemId: $0.saleItemId, name: $0.name, imageName: imageName, price: $0.price, qty: $0.qty, createdAt: $0.createdAt)
        }, payments: order.payments, statusLog: order.statusLog, createdAt: order.createdAt)
        try await store.execute(
            query: """
                INSERT INTO pos_orders
                DOCUMENTS (deserialize_json(:json))
                ON ID CONFLICT DO UPDATE_LOCAL_DIFF
                """,
            arguments: ["json": try document.dittoJSONString()])
    }
}
