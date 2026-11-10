import DittoSwift
import Foundation

enum PhotoAttachments {
    static func configure(store: DittoStore) async throws {
        try await store.execute(query: "ALTER SYSTEM SET attachments_auto_fetch = true")
    }

    static func importPhoto(_ data: Data, mimeType: String, store: DittoStore) async throws -> DittoAttachment {
        try await store.newAttachment(data: data, metadata: ["mime_type": mimeType])
    }

    static func reference(to attachment: DittoAttachment) -> PhotoReference {
        PhotoReference(id: attachment.id, len: attachment.len, metadata: attachment.metadata)
    }

    // Attachments must cross the SDK binding directly, outside ordinary JSON encoding.
    // https://docs.ditto.live/sdk/latest/crud/working-with-attachments
    static func replace(_ attachment: DittoAttachment, for id: DocumentID, executor: any DittoQueryExecuting & Sendable) async throws {
        try await executor.execute(
            query: """
                UPDATE COLLECTION sale_items (image ATTACHMENT) SET image = :image
                WHERE _id.id = :id AND _id.locationId = :locationId
                """,
            arguments: ["image": attachment, "id": id.id, "locationId": id.locationId]
        )
    }

    static func remove(for id: DocumentID, executor: any DittoQueryExecuting & Sendable) async throws {
        try await executor.execute(
            query: """
                UPDATE COLLECTION sale_items (image ATTACHMENT) UNSET image
                WHERE _id.id = :id AND _id.locationId = :locationId
                """,
            arguments: ["id": id.id, "locationId": id.locationId]
        )
    }
}
