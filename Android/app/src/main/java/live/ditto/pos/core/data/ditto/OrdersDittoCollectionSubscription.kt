package live.ditto.pos.core.data.ditto

import live.ditto.ditto_wrapper.DittoPropertyDeserializer
import live.ditto.ditto_wrapper.dittowrappers.DittoCollectionSubscription
import live.ditto.pos.core.data.Order

class OrdersDittoCollectionSubscription(
    private val locationId: String,
    private val ordersDittoPropertyDeserializer: DittoPropertyDeserializer<List<Order>>
) : DittoCollectionSubscription<List<Order>> {
    override val collectionName: String
        get() = ORDERS_COLLECTION_NAME
    override val subscriptionQuery: String
        get() = DEFAULT_LOCATION_SYNC_QUERY
    override val subscriptionQueryArgs: Map<String, Any>
        get() = mapOf("locationId" to locationId)
    override val evictionQuery: String
        get() = "todo"
    override val deserializer: DittoPropertyDeserializer<List<Order>>
        get() = ordersDittoPropertyDeserializer
}
