package live.ditto.pos.core.data.transactions

data class Transaction(
    val id: Map<String, String>,
    val createdOn: String,
    val type: Int,
    val status: Int,
    val amount: Double
) {

    fun getTransactionId(): String {
        return id["id"] ?: ""
    }

    fun serializeAsMap(): Map<String, Any> {
        return mapOf(
            "_id" to id,
            "createdOn" to createdOn,
            "type" to type,
            "status" to status,
            "amount" to amount
        )
    }
}
