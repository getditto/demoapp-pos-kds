package live.ditto.pos.core.data.orders

import live.ditto.pos.core.data.OrderStatus

internal object KitchenOrders {
    // A stale transition must not reopen a more advanced or terminal ticket.
    // https://docs.ditto.live/best-practices/conflict-resolution-patterns
    val query = """
        SELECT * FROM ${Order.COLLECTION_NAME}
        WHERE _id.locationId = :locationId
            AND object_length(cart) > 0
            AND (
                array_contains(object_values(status_log), 'inProcess')
                OR array_contains(object_values(status_log), 'processed')
            )
            AND NOT array_contains(object_values(status_log), 'delivered')
            AND NOT array_contains(object_values(status_log), 'canceled')
        ORDER BY array_contains(object_values(status_log), 'processed'), createdAt DESC, _id.id
    """.trimIndent()

    fun nextStatus(status: OrderStatus): OrderStatus? = when (status) {
        OrderStatus.IN_PROCESS -> OrderStatus.PROCESSED
        OrderStatus.PROCESSED -> OrderStatus.DELIVERED
        else -> null
    }
}
