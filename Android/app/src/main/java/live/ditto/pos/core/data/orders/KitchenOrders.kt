package live.ditto.pos.core.data.orders

import live.ditto.pos.core.data.OrderStatus

internal object KitchenOrders {
    val query = """
        SELECT * FROM ${Order.COLLECTION_NAME}
        WHERE _id.locationId = :locationId
            AND object_length(cart) > 0
        ORDER BY createdAt DESC
    """.trimIndent()

    fun active(orders: List<Order>): List<Order> = orders.filter {
        when (it.status) {
            OrderStatus.IN_PROCESS, OrderStatus.PROCESSED -> true
            else -> false
        }
    }

    fun nextStatus(status: OrderStatus): OrderStatus? = when (status) {
        OrderStatus.IN_PROCESS -> OrderStatus.PROCESSED
        OrderStatus.PROCESSED -> OrderStatus.DELIVERED
        else -> null
    }
}
