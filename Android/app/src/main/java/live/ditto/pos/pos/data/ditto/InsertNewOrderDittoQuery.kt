package live.ditto.pos.pos.data.ditto

import live.ditto.ditto_wrapper.dittowrappers.DittoQuery
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.data.orders.ditto.INSERT_NEW_ORDER_QUERY

class InsertNewOrderDittoQuery(private val order: Order) : DittoQuery {

    override val queryString = INSERT_NEW_ORDER_QUERY.trimIndent()
    override val arguments: Map<String, Any>
        get() = mapOf("new" to order.serializeAsMap())
}
