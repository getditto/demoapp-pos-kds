package live.ditto.pos.core.data.ditto.orders

import live.ditto.ditto_wrapper.dittowrappers.DittoCollectionSubscription

class OrdersDittoCollectionSubscription(
    locationId: String
) : DittoCollectionSubscription {

    override val collectionName = ORDERS_COLLECTION_NAME
    override val subscriptionQuery = SUBSCRIPTION_QUERY.trimIndent()
    override val subscriptionQueryArgs: Map<String, Any> = mapOf(LOCATION_ID_ATTRIBUTE_KEY to locationId)
    override val evictionQuery = "todo" // todo
}
