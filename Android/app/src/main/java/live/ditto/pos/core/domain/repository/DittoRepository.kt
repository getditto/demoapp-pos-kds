package live.ditto.pos.core.domain.repository

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import live.ditto.Ditto
import live.ditto.ditto_wrapper.DittoManager
import live.ditto.ditto_wrapper.DittoStoreManager
import live.ditto.pos.core.data.locations.Location
import live.ditto.pos.core.data.locations.ditto.GetAllLocationsDittoSelectQuery
import live.ditto.pos.core.data.locations.ditto.InsertCustomLocationDittoQuery
import live.ditto.pos.core.data.locations.ditto.LocationsDittoCollectionSubscription
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.data.orders.OrderStatus
import live.ditto.pos.core.data.orders.ditto.AddTransactionToOrderDittoQuery
import live.ditto.pos.core.data.orders.ditto.GetOrdersForLocationDittoQuery
import live.ditto.pos.core.data.orders.ditto.OrdersDittoCollectionSubscription
import live.ditto.pos.core.data.transactions.Transaction
import live.ditto.pos.core.data.transactions.ditto.AddNewTransactionDittoQuery
import live.ditto.pos.pos.data.ditto.AddItemToOrderDittoQuery
import live.ditto.pos.pos.data.ditto.ClearSaleItemsDittoQuery
import live.ditto.pos.pos.data.ditto.InsertNewOrderDittoQuery
import live.ditto.pos.pos.data.ditto.UpdateOrderStatusDittoQuery
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

    fun getDeviceId(): String {
        return dittoManager.requireDitto().siteId.toString()
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

    suspend fun updateOrderStatus(order: Order, orderStatus: OrderStatus) {
        val updateOrderStatusQuery = UpdateOrderStatusDittoQuery(
            orderId = order.id,
            orderStatus = orderStatus
        )
        dittoStoreManager.executeQuery(dittoQuery = updateOrderStatusQuery)
    }

    suspend fun getLocationById(locationId: String): Location? {
        return dittoStoreManager.executeQuery(GetAllLocationsDittoSelectQuery())
            .first()
            .find { it.id == locationId }
    }

    suspend fun addTransaction(
        transaction: Transaction,
        order: Order
    ) {
        val addNewTransactionQuery = AddNewTransactionDittoQuery(
            transaction = transaction
        )
        dittoStoreManager.executeQuery(dittoQuery = addNewTransactionQuery)

        val addTransactionToOrderQuery = AddTransactionToOrderDittoQuery(
            transaction = transaction,
            orderId = order.id
        )
        dittoStoreManager.executeQuery(dittoQuery = addTransactionToOrderQuery)
    }

    suspend fun clearSaleItemIds(order: Order) {
        val clearSaleItemsDittoQuery = ClearSaleItemsDittoQuery(order = order)
        dittoStoreManager.executeQuery(dittoQuery = clearSaleItemsDittoQuery)
    }

    suspend fun insertCustomLocation(customLocation: Location) {
        val insertCustomLocationQuery = InsertCustomLocationDittoQuery(
            customLocation = customLocation
        )
        dittoStoreManager.executeQuery(dittoQuery = insertCustomLocationQuery)
    }
}
