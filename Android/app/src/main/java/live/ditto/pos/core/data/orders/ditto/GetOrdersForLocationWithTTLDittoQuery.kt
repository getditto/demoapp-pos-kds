package live.ditto.pos.core.data.orders.ditto

import kotlinx.datetime.Clock
import live.ditto.ditto_wrapper.DittoPropertyDeserializer
import live.ditto.ditto_wrapper.dittowrappers.DittoSelectQuery
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.data.orders.toOrder
import kotlin.time.Duration.Companion.hours

class GetOrdersForLocationWithTTLDittoQuery(
    locationId: String,
    ttlHours: Int = 24
) : DittoSelectQuery<List<Order>> {

    override val queryString: String = GET_ORDERS_FOR_LOCATION_WITH_TTL_QUERY.trimIndent()
    override val arguments: Map<String, Any> = mapOf(
        LOCATION_ID_ATTRIBUTE_KEY to locationId,
        TTL_ATTRIBUTE_KEY to calculateTTL(ttlHours)
    )
    override val documentDeserializer: DittoPropertyDeserializer<List<Order>>
        get() = { dittoProperties ->
            dittoProperties.map { it.toOrder() }
        }

    private fun calculateTTL(hours: Int): String {
        val ttlInstant = Clock.System.now().minus(hours.hours)
        return ttlInstant.toString()
    }
}
