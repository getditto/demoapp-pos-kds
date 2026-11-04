package live.ditto.pos.core.data.orders

import live.ditto.pos.core.data.OrderStatus

internal object KitchenOrders {
    fun select(orders: List<Order>): List<Order> {
        val eligible = orders.filter {
            (it.status == OrderStatus.IN_PROCESS || it.status == OrderStatus.PROCESSED) && it.cart.isNotEmpty()
        }
        return eligible.filter { it.status == OrderStatus.IN_PROCESS }.sortedByDescending { it.createdAt } +
            eligible.filter { it.status == OrderStatus.PROCESSED }.sortedByDescending { it.createdAt }
    }

    fun nextStatus(status: OrderStatus): OrderStatus? = when (status) {
        OrderStatus.IN_PROCESS -> OrderStatus.PROCESSED
        OrderStatus.PROCESSED -> OrderStatus.DELIVERED
        else -> null
    }
}
