package live.ditto.pos.core.data.orders.ditto

import live.ditto.ditto_wrapper.dittowrappers.DittoQuery
import live.ditto.pos.core.data.transactions.Transaction

class AddTransactionToOrderDittoQuery(
    private val transaction: Transaction,
    private val orderId: Map<String, String>
) : DittoQuery {

    override val queryString: String
        get() = ADD_TRANSACTION_TO_ORDER_QUERY
            .replace(ORDERS_TRANSACTION_ID_PLACEHOLDER, transaction.getTransactionId())
            .trimIndent()

    override val arguments: Map<String, Any>
        get() = mapOf(
            "status" to transaction.status,
            "_id" to orderId
        )
}
