package live.ditto.pos.core.domain.repository

import kotlinx.coroutines.flow.Flow
import live.ditto.Ditto
import live.ditto.ditto_wrapper.DittoManager
import live.ditto.ditto_wrapper.DittoStoreManager
import live.ditto.pos.core.data.Order
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.core.data.ditto.orders.GetAllOrdersForLocationDittoQuery
import live.ditto.pos.core.data.ditto.orders.InsertNewOrderDittoQuery
import live.ditto.pos.core.data.ditto.orders.OrdersDittoCollectionSubscription
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class DittoRepository @Inject constructor(
    private val dittoManager: DittoManager,
    private val dittoStoreManager: DittoStoreManager
) {

    fun requireDitto(): Ditto {
        return dittoManager.requireDitto()
    }

    fun insertDefaultLocations() {
        TODO("Not yet implemented")
    }

    fun refreshPermissions() {
        dittoManager.requireDitto().refreshPermissions()
    }

    fun getMissingPermissions(): Array<String> {
        return dittoManager.missingPermissions()
    }

    fun startOrdersSubscription(locationId: String) {
        val ordersDittoCollectionSubscription = OrdersDittoCollectionSubscription(
            locationId = locationId
        )
        dittoStoreManager.registerSubscription(
            dittoCollectionSubscription = ordersDittoCollectionSubscription
        )
    }

    fun ordersForLocation(locationId: String, orderStatus: OrderStatus): Flow<List<Order>> {
        return dittoStoreManager.observeLiveQueryAsFlow(
            GetAllOrdersForLocationDittoQuery(
                locationId = locationId,
                orderStatus = orderStatus
            )
        )
    }

    suspend fun insertNewOrder(order: Order) {
        val insertNewOrderQuery = InsertNewOrderDittoQuery(
            order = order
        )
        dittoStoreManager.executeQuery(dittoQuery = insertNewOrderQuery)
    }
}
