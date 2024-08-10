package live.ditto.pos.core.data.ditto.orders

import live.ditto.ditto_wrapper.DittoPropertyDeserializer
import live.ditto.ditto_wrapper.dittowrappers.DittoSelectQuery
import live.ditto.pos.core.data.Order
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.core.data.toOrder

class GetAllOrdersForLocationDittoQuery(
    locationId: String,
    orderStatus: OrderStatus
) : DittoSelectQuery<List<Order>> {

    override val queryString: String = GET_ALL_OPEN_ORDERS_FOR_LOCATION_QUERY.trimIndent()
    override val arguments: Map<String, Any> = mapOf(
        LOCATION_ID_ATTRIBUTE_KEY to locationId,
        STATUS_ATTRIBUTE_KEY to orderStatus.ordinal
    )
    override val documentDeserializer: DittoPropertyDeserializer<List<Order>>
        get() = { dittoProperties ->
            dittoProperties.map { it.toOrder() }
        }
}
