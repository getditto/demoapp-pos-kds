package live.ditto.pos.core.data.orders.ditto

import live.ditto.ditto_wrapper.DittoPropertyDeserializer
import live.ditto.ditto_wrapper.dittowrappers.DittoSelectQuery
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.data.orders.toOrder

class GetOrdersForLocationDittoQuery(
    locationId: String
) : DittoSelectQuery<List<Order>> {

    override val queryString: String = GET_ORDERS_FOR_LOCATION_QUERY.trimIndent()
    override val arguments: Map<String, Any> = mapOf(
        LOCATION_ID_ATTRIBUTE_KEY to locationId
    )
    override val documentDeserializer: DittoPropertyDeserializer<List<Order>>
        get() = { dittoProperties ->
            dittoProperties.map { it.toOrder() }
        }
}
