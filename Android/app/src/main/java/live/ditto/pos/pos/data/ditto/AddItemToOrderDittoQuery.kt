package live.ditto.pos.pos.data.ditto

import live.ditto.ditto_wrapper.dittowrappers.DittoQuery
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.core.data.ditto.orders.ADD_ITEM_TO_ORDER_QUERY
import live.ditto.pos.core.data.ditto.orders.ORDERS_SALE_ITEM_ID_PLACEHOLDER

class AddItemToOrderDittoQuery(
    private val orderId: Map<String, String>,
    private val orderStatus: OrderStatus,
    private val saleItemIdKey: String,
    private val saleItemIdValue: String
) : DittoQuery {

    override val queryString: String
        get() = ADD_ITEM_TO_ORDER_QUERY.trimIndent().replace(ORDERS_SALE_ITEM_ID_PLACEHOLDER, "`$saleItemIdKey`")
    override val arguments: Map<String, Any>
        get() = mapOf(
            "_id" to orderId,
            "status" to orderStatus.ordinal,
            "saleItemIdValue" to saleItemIdValue
        )
}