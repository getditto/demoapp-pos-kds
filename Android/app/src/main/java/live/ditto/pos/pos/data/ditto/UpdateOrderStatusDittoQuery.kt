package live.ditto.pos.pos.data.ditto

import live.ditto.ditto_wrapper.dittowrappers.DittoQuery
import live.ditto.pos.core.data.orders.OrderStatus
import live.ditto.pos.core.data.orders.ditto.UPDATE_ORDER_STATUS_QUERY

class UpdateOrderStatusDittoQuery(
    private val orderId: Map<String, String>,
    private val orderStatus: OrderStatus
) : DittoQuery {

    override val queryString = UPDATE_ORDER_STATUS_QUERY.trimIndent()
    override val arguments: Map<String, Any>
        get() = mapOf(
            "_id" to orderId,
            "status" to orderStatus.ordinal
        )
}
