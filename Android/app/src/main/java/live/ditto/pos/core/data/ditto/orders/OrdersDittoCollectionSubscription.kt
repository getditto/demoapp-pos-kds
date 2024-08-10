package live.ditto.pos.core.data.ditto.orders

import live.ditto.ditto_wrapper.dittowrappers.DittoCollectionSubscription
import live.ditto.pos.core.data.Order

class OrdersDittoCollectionSubscription(
    private val locationId: String
) : DittoCollectionSubscription<List<Order>> {

    companion object {
    }

    override val collectionName: String = ORDERS_COLLECTION_NAME
    override val subscriptionQuery: String = SUBSCRIPTION_QUERY.trimIndent()
    override val subscriptionQueryArgs: Map<String, Any> = mapOf(LOCATION_ID_ATTRIBUTE_KEY to locationId)
    override val evictionQuery: String = "todo"
}
