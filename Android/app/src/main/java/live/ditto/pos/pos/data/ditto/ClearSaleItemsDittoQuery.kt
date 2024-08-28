package live.ditto.pos.pos.data.ditto

import live.ditto.ditto_wrapper.dittowrappers.DittoQuery
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.data.orders.ditto.CLEAR_SALE_ITEMS_ORDER_QUERY

class ClearSaleItemsDittoQuery(
    val order: Order
) : DittoQuery {

    override val queryString = CLEAR_SALE_ITEMS_ORDER_QUERY.trimIndent()
    override val arguments: Map<String, Any>
        get() = mapOf(
            "_id" to order.id
        )
}
