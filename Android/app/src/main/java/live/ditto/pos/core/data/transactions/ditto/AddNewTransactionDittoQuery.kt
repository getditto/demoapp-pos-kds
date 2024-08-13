package live.ditto.pos.core.data.transactions.ditto

import live.ditto.ditto_wrapper.dittowrappers.DittoQuery
import live.ditto.pos.core.data.transactions.Transaction

class AddNewTransactionDittoQuery(
    private val transaction: Transaction
) : DittoQuery {

    override val queryString = INSERT_NEW_TRANSACTION_QUERY.trimIndent()
    override val arguments: Map<String, Any>
        get() = mapOf(
            "new" to transaction.serializeAsMap()
        )
}
