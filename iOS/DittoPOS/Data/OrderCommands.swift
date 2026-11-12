import DittoSwift
import Foundation

enum OrderCommands {
    static func upsert(_ order: Order, store: DittoStore) async throws {
        let json = try order.dittoJSONString()
        // The metadata and typed photo references become visible together.
        // https://docs.ditto.live/sdk/latest/crud/transactions
        try await store.transaction { transaction in
            try await transaction.execute(
                query: "INSERT INTO pos_orders DOCUMENTS (deserialize_json(:json)) ON ID CONFLICT DO UPDATE_LOCAL_DIFF",
                arguments: ["json": json]
            )
            for (lineItemId, line) in order.cart.sorted(by: { $0.key < $1.key }) {
                if let image = line.image {
                    try await PhotoAttachments.copy(image, to: order.documentId, lineItemId: lineItemId, executor: transaction)
                }
            }
            return .commit
        }
    }

    static func addPayment(_ payment: Payment, paymentId: String, to id: DocumentID, executor: any DittoQueryExecuting & Sendable) async throws {
        try await executor.execute(
            query: "UPDATE pos_orders SET payments.\(dqlIdentifier(paymentId)) = deserialize_json(:payment) WHERE _id.id = :id AND _id.locationId = :locationId",
            arguments: ["payment": try payment.dittoJSONString(), "id": id.id, "locationId": id.locationId]
        )
    }

    static func clearCart(of order: Order, executor: any DittoQueryExecuting & Sendable) async throws {
        guard !order.cart.isEmpty else { return }
        // Map entries need explicit removal; omitting them in an upsert retains them.
        // https://docs.ditto.live/dql/update
        let paths = order.cart.keys.sorted().map { "cart.\(dqlIdentifier($0))" }.joined(separator: ", ")
        try await executor.execute(
            query: "UPDATE pos_orders UNSET \(paths) WHERE _id.id = :id AND _id.locationId = :locationId",
            arguments: ["id": order.documentId.id, "locationId": order.documentId.locationId]
        )
    }

    static func updateStatus(_ status: OrderStatus, of id: DocumentID, at date: Date = Date(), executor: any DittoQueryExecuting & Sendable) async throws {
        let entry = StatusLogDerivation.entry(status, at: date)
        try await executor.execute(
            query: "UPDATE pos_orders SET status_log.\(dqlIdentifier(entry.timestamp)) = :status WHERE _id.id = :id AND _id.locationId = :locationId",
            arguments: ["status": entry.status, "id": id.id, "locationId": id.locationId]
        )
    }
}

func dqlIdentifier(_ value: String) -> String {
    "`\(value.replacingOccurrences(of: "`", with: "``"))`"
}
