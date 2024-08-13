package live.ditto.pos.core.data.locations.ditto

import live.ditto.ditto_wrapper.dittowrappers.DittoCollectionSubscription

class LocationsDittoCollectionSubscription : DittoCollectionSubscription {

    override val collectionName = LOCATIONS_COLLECTIONS_NAME
    override val subscriptionQuery = LOCATIONS_SUBSCRIPTION_QUERY.trimIndent()
    override val subscriptionQueryArgs = emptyMap<String, Any>()
    override val evictionQuery = "todo" // todo
}
