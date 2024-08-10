package live.ditto.pos.core.domain.repository

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import live.ditto.Ditto
import live.ditto.ditto_wrapper.DittoManager
import live.ditto.ditto_wrapper.DittoStoreManager
import live.ditto.pos.core.data.Location
import live.ditto.pos.core.data.Order
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.core.data.ditto.location.GetAllLocationsDittoSelectQuery
import live.ditto.pos.core.data.ditto.location.LocationsDittoCollectionSubscription
import live.ditto.pos.core.data.ditto.orders.GetOrdersForLocationDittoQuery
import live.ditto.pos.core.data.ditto.orders.OrdersDittoCollectionSubscription
import live.ditto.pos.pos.data.ditto.AddItemToOrderDittoQuery
import live.ditto.pos.pos.data.ditto.InsertNewOrderDittoQuery
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

    fun startLocationSubscription() {
        dittoStoreManager.registerSubscription(LocationsDittoCollectionSubscription())
    }

    fun ordersForLocation(locationId: String): Flow<List<Order>> {
        return dittoStoreManager.observeLiveQueryAsFlow(
            GetOrdersForLocationDittoQuery(
                locationId = locationId
            )
        )
    }

    suspend fun insertNewOrder(order: Order) {
        val insertNewOrderQuery = InsertNewOrderDittoQuery(
            order = order
        )
        dittoStoreManager.executeQuery(dittoQuery = insertNewOrderQuery)
    }

    suspend fun addItemToOrder(
        order: Order,
        saleItemIdKey: String,
        saleItemId: String
    ) {
        val addItemToOrderDittoQuery = AddItemToOrderDittoQuery(
            orderId = order.id,
            orderStatus = OrderStatus.IN_PROCESS,
            saleItemIdKey = saleItemIdKey,
            saleItemIdValue = saleItemId
        )
        dittoStoreManager.executeQuery(dittoQuery = addItemToOrderDittoQuery)
    }

    suspend fun getLocationById(locationId: String): Location? {
        return dittoStoreManager.executeQuery(GetAllLocationsDittoSelectQuery())
            .first()
            .find { it.id == locationId }
    }
}
