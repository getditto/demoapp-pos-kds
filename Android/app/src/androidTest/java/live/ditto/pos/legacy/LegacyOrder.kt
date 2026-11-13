// Pinned beab457 serialization; only test package/type names differ.
package live.ditto.pos.legacy

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import live.ditto.pos.core.data.DittoInstantSerializer
import live.ditto.pos.core.data.DocumentID
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.core.data.Payment
import live.ditto.pos.core.data.Price
import live.ditto.pos.core.data.StatusLogDerivation
import live.ditto.pos.legacy.LegacyCartLineItem
import java.util.UUID
import kotlin.time.Clock
import kotlin.time.Instant

@Serializable
data class LegacyOrder(
    @SerialName("_id") val documentId: DocumentID,
    val cart: Map<String, LegacyCartLineItem> = emptyMap(),
    val payments: Map<String, Payment> = emptyMap(),
    @SerialName("status_log") val statusLog: Map<String, String> = emptyMap(),
    @Serializable(with = DittoInstantSerializer::class)
    val createdAt: Instant
) {
    val title: String get() = documentId.id.take(8)

    val status: OrderStatus get() = StatusLogDerivation.currentStatus(statusLog)
    val isPaid: Boolean get() = status == OrderStatus.CANCELED || payments.isNotEmpty()

    val sortedLineItems: List<LegacyCartLineItem>
        get() = cart.values.sortedBy { it.createdAt }

    val totalCents: Int get() = sortedLineItems.sumOf { it.price.amount * it.qty }
    val total: Price get() = Price(totalCents)

    /** name → quantity, used by KDS summary view. */
    val summary: Map<String, Int>
        get() = sortedLineItems.groupingBy { it.name }.fold(0) { acc, line -> acc + line.qty }

    fun addingCartLineItem(lineItem: LegacyCartLineItem, lineItemId: String): LegacyOrder {
        val (timestamp, statusValue) = StatusLogDerivation.entry(OrderStatus.IN_PROCESS)
        return copy(
            cart = cart + (lineItemId to lineItem),
            statusLog = statusLog + (timestamp to statusValue)
        )
    }

    fun addingPayment(payment: Payment, paymentId: String): LegacyOrder =
        copy(payments = payments + (paymentId to payment))

    fun appendingStatus(newStatus: OrderStatus, at: Instant = Clock.System.now()): LegacyOrder {
        val (timestamp, statusValue) = StatusLogDerivation.entry(newStatus, at = at)
        return copy(statusLog = statusLog + (timestamp to statusValue))
    }

    companion object {
        const val COLLECTION_NAME = "pos_orders"

        fun new(
            locationId: String,
            createdAt: Instant = Clock.System.now(),
            status: OrderStatus = OrderStatus.OPEN
        ): LegacyOrder {
            val (timestamp, statusValue) = StatusLogDerivation.entry(status, at = createdAt)
            return LegacyOrder(
                documentId = DocumentID(id = UUID.randomUUID().toString(), locationId = locationId),
                cart = emptyMap(),
                payments = emptyMap(),
                statusLog = mapOf(timestamp to statusValue),
                createdAt = createdAt
            )
        }
    }
}
