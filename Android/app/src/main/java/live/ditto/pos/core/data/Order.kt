package live.ditto.pos.core.data

import live.ditto.ditto_wrapper.DittoProperty
import live.ditto.ditto_wrapper.MissingPropertyException
import live.ditto.ditto_wrapper.deserializeProperty

data class Order(
    val id: Map<String, String>,
    val createdOn: String,
    val deviceId: String,
    val saleItemIds: Map<String, String>?, // id to sale item id
    val status: Int,
    val transactionIds: Map<String, Int>
) {
    fun allSaleItemIds(): Collection<String>? {
        return saleItemIds?.values
    }
}

fun DittoProperty.toOrder(): Order {
    return Order(
        id = deserializeProperty("_id"),
        createdOn = deserializeProperty("createdOn"),
        deviceId = deserializeProperty("deviceId"),
        saleItemIds = try { deserializeProperty<Map<String, String>?>("saleItemIds") } catch (e: MissingPropertyException) {
            null
        },
        status = deserializeProperty("status"),
        transactionIds = deserializeProperty("transactionIds")
    )
}

fun List<Order>.findOrderById(id: String): Order? {
    return find {
        it.id["id"] == id
    }
}
