package live.ditto.pos.core.data.orders

import kotlinx.datetime.Instant
import live.ditto.ditto_wrapper.DittoProperty
import live.ditto.ditto_wrapper.MissingPropertyException
import live.ditto.ditto_wrapper.deserializeProperty

data class Order(
    val id: Map<String, String>,
    val createdOn: String,
    val deviceId: String,
    val saleItemIds: MutableMap<String, String>?, // id to sale item id
    val status: Int,
    val transactionIds: Map<String, Int>
) {
    fun sortedSaleItemIds(): Collection<String>? {
        return saleItemIds?.mapKeys {
            Instant.parse(it.key.substringAfter("_"))
        }
            ?.toSortedMap()
            ?.values
    }

    fun getOrderId(): String {
        return id["id"] ?: ""
    }

    fun serializeAsMap(): Map<String, Any> {
        val orderMap = mutableMapOf<String, Any>()
        return orderMap.apply {
            this["_id"] = id
            this["createdOn"] = createdOn
            this["deviceId"] = deviceId
            saleItemIds?.let { this["saleItemIds"] = it }
            this["status"] = status
            this["transactionIds"] = transactionIds
        }
    }
}

fun DittoProperty.toOrder(): Order {
    return Order(
        id = deserializeProperty("_id"),
        createdOn = deserializeProperty("createdOn"),
        deviceId = deserializeProperty("deviceId"),
        saleItemIds = try {
            deserializeProperty<MutableMap<String, String>?>("saleItemIds")
        } catch (e: MissingPropertyException) {
            null
        },
        status = deserializeProperty("status"),
        transactionIds = deserializeProperty("transactionIds")
    )
}

fun List<Order>.findOrderById(id: String): Order? {
    return find {
        it.getOrderId() == id
    }
}
