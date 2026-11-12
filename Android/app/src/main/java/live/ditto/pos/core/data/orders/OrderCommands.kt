package live.ditto.pos.core.data.orders

import com.ditto.kotlin.DittoStore
import com.ditto.kotlin.DittoTransaction
import live.ditto.pos.core.data.DocumentID
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.core.data.Payment
import live.ditto.pos.core.data.StatusLogDerivation
import live.ditto.pos.core.data.dittoJsonString
import live.ditto.pos.core.data.images.PhotoAttachments
import kotlin.time.Clock
import kotlin.time.Instant

object OrderCommands {
    suspend fun upsert(order: Order, store: DittoStore) {
        val metadata = order.copy(cart = order.cart.mapValues { it.value.copy(image = null) })
        // The metadata and typed photo references become visible together.
        // https://docs.ditto.live/sdk/latest/crud/transactions
        store.transaction { transaction ->
            transaction.execute(
                "INSERT INTO pos_orders DOCUMENTS (deserialize_json(:json)) ON ID CONFLICT DO UPDATE_LOCAL_DIFF",
                mapOf("json" to metadata.dittoJsonString())
            )
            for ((lineItemId, line) in order.cart.toSortedMap()) {
                line.image?.let { PhotoAttachments.copy(it, order.documentId, lineItemId, transaction) }
            }
            DittoTransaction.Result.Commit()
        }
    }

    suspend fun addPayment(payment: Payment, paymentId: String, id: DocumentID, store: DittoStore) {
        store.execute(
            "UPDATE pos_orders SET payments.${dqlIdentifier(paymentId)} = deserialize_json(:payment) WHERE _id.id = :id AND _id.locationId = :locationId",
            mapOf("payment" to payment.dittoJsonString(), "id" to id.id, "locationId" to id.locationId)
        )
    }

    suspend fun clearCart(order: Order, store: DittoStore) {
        if (order.cart.isEmpty()) return
        // Map entries need explicit removal; omitting them in an upsert retains them.
        // https://docs.ditto.live/dql/update
        store.execute(
            "UPDATE pos_orders UNSET ${order.cartPathsForUnset()} WHERE _id.id = :id AND _id.locationId = :locationId",
            mapOf("id" to order.documentId.id, "locationId" to order.documentId.locationId)
        )
    }

    suspend fun updateStatus(status: OrderStatus, id: DocumentID, store: DittoStore, at: Instant = Clock.System.now()) {
        val (timestamp, value) = StatusLogDerivation.entry(status, at)
        store.execute(
            "UPDATE pos_orders SET status_log.${dqlIdentifier(timestamp)} = :status WHERE _id.id = :id AND _id.locationId = :locationId",
            mapOf("status" to value, "id" to id.id, "locationId" to id.locationId)
        )
    }
}
