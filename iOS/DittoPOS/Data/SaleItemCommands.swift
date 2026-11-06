import DittoSwift
import Foundation

enum SaleItemCommands {
    // Stock deltas from different peers must compose.
    // https://docs.ditto.live/dql/types-and-definitions#counter-settable-counter
    static let creationCollection = "COLLECTION sale_items (quantity COUNTER)"

    static func create(_ payload: SaleItemCreation, store: DittoStore) async throws {
        guard payload.initialQuantity >= 0 else { throw Validation.negativeQuantity }
        _ = try await store.execute(
            query: "INSERT INTO \(creationCollection) DOCUMENTS (deserialize_json(:json))",
            arguments: ["json": try payload.dittoJSONString()]
        )
    }

    static func updateMetadata(_ metadata: SaleItemMetadata, store: DittoStore) async throws {
        _ = try await store.execute(
            query: """
                UPDATE sale_items
                SET name = :name, imageName = :imageName, price = deserialize_json(:price)
                WHERE _id.id = :id AND _id.locationId = :locationId
                """,
            arguments: [
                "name": metadata.name, "imageName": metadata.imageName,
                "price": try metadata.price.dittoJSONString(),
                "id": metadata.documentId.id, "locationId": metadata.documentId.locationId
            ]
        )
    }

    static func increment(_ delta: Int64, id: DocumentID, store: DittoStore) async throws {
        try await counter("INCREMENT BY", value: delta, id: id, store: store)
    }

    static func restart(_ quantity: Int64, id: DocumentID, store: DittoStore) async throws {
        guard quantity >= 0 else { throw Validation.negativeQuantity }
        try await counter("RESTART WITH", value: quantity, id: id, store: store)
    }

    private static func counter(_ operation: String, value: Int64, id: DocumentID, store: DittoStore) async throws {
        _ = try await store.execute(
            query: """
                UPDATE sale_items APPLY quantity \(operation) :value
                WHERE _id.id = :id AND _id.locationId = :locationId
                """,
            arguments: ["value": value, "id": id.id, "locationId": id.locationId]
        )
    }

    enum Validation: Error { case negativeQuantity }
}
