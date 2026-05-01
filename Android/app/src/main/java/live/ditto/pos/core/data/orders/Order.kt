package live.ditto.pos.core.data.orders

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import live.ditto.pos.core.data.CartLineItem
import live.ditto.pos.core.data.DocumentID
import live.ditto.pos.core.data.Money
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.core.data.Payment
import live.ditto.pos.core.data.StatusLogDerivation
import live.ditto.pos.core.data.isoNow
import java.util.UUID

@Serializable
data class Order(
    @SerialName("_id") val documentId: DocumentID,
    val cart: Map<String, CartLineItem> = emptyMap(),
    val payments: Map<String, Payment> = emptyMap(),
    @SerialName("status_log") val statusLog: Map<String, String> = emptyMap(),
    val createdOn: String
) {
    val id: String get() = documentId.id
    val locationId: String get() = documentId.locationId
    val title: String get() = id.take(8)

    val status: OrderStatus get() = StatusLogDerivation.currentStatus(statusLog)
    val isPaid: Boolean get() = status == OrderStatus.CANCELED || payments.isNotEmpty()

    val sortedLineItems: List<CartLineItem>
        get() = cart.values.sortedBy { it.createdOn }

    val totalCents: Int get() = sortedLineItems.sumOf { it.price.amount * it.qty }
    val total: Money get() = Money(totalCents)

    /** name → quantity, used by KDS summary view. */
    val summary: Map<String, Int>
        get() = sortedLineItems.groupingBy { it.name }.fold(0) { acc, line -> acc + line.qty }

    fun addingCartLineItem(lineItem: CartLineItem, lineItemId: String): Order {
        val (timestamp, statusValue) = StatusLogDerivation.entry(OrderStatus.IN_PROCESS)
        return copy(
            cart = cart + (lineItemId to lineItem),
            statusLog = statusLog + (timestamp to statusValue)
        )
    }

    fun addingPayment(payment: Payment, paymentId: String): Order =
        copy(payments = payments + (paymentId to payment))

    fun appendingStatus(newStatus: OrderStatus, at: String = isoNow()): Order {
        val (timestamp, statusValue) = StatusLogDerivation.entry(newStatus, at = at)
        return copy(statusLog = statusLog + (timestamp to statusValue))
    }

    companion object {
        const val COLLECTION_NAME = "pos_orders"

        fun new(
            locationId: String,
            createdOn: String = isoNow(),
            status: OrderStatus = OrderStatus.OPEN
        ): Order {
            val (timestamp, statusValue) = StatusLogDerivation.entry(status, at = createdOn)
            return Order(
                documentId = DocumentID(id = UUID.randomUUID().toString(), locationId = locationId),
                cart = emptyMap(),
                payments = emptyMap(),
                statusLog = mapOf(timestamp to statusValue),
                createdOn = createdOn
            )
        }
    }
}
