package live.ditto.pos.core.data.orders

import live.ditto.pos.core.data.OrderStatus

internal object OrderSelection {
    fun reusableOrderId(savedId: String, orders: List<Order>): String? =
        orders.firstOrNull { it.documentId.id == savedId }
            ?.takeIf { it.status == OrderStatus.OPEN || it.status == OrderStatus.IN_PROCESS }
            ?.documentId?.id
}
