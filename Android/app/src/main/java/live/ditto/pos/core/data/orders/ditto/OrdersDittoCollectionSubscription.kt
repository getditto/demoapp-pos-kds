package live.ditto.pos.core.data.orders.ditto

import kotlinx.datetime.Clock
import live.ditto.ditto_wrapper.dittowrappers.DittoCollectionSubscription
import kotlin.time.Duration.Companion.hours

class OrdersDittoCollectionSubscription(
    locationId: String,
    ttlHours: Int = 24
) : DittoCollectionSubscription {

    override val collectionName = ORDERS_COLLECTION_NAME
    override val subscriptionQuery = SUBSCRIPTION_QUERY.trimIndent()
    override val subscriptionQueryArgs: Map<String, Any> = mapOf(
        LOCATION_ID_ATTRIBUTE_KEY to locationId,
        TTL_ATTRIBUTE_KEY to calculateTTL(ttlHours)
    )
    override val evictionQuery = "todo" // todo

    private fun calculateTTL(hours: Int): String {
        val ttlInstant = Clock.System.now().minus(hours.hours)
        return ttlInstant.toString()
    }
}
