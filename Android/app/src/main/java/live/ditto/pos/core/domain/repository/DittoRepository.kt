package live.ditto.pos.core.domain.repository

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import live.ditto.Ditto
import live.ditto.ditto_wrapper.DittoManager
import live.ditto.ditto_wrapper.DittoStoreManager
import live.ditto.pos.core.data.Order
import live.ditto.pos.core.data.ditto.OrdersDittoCollectionSubscription
import live.ditto.pos.core.data.toOrder
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class DittoRepository @Inject constructor(
    private val dittoManager: DittoManager,
    private val dittoStoreManager: DittoStoreManager,
    private val coreRepository: CoreRepository
) {

    private var ordersSubscription: Flow<List<Order>>? = null

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

    suspend fun startOrdersSubscription() {
        val locationId = coreRepository.locationId()
        val ordersDittoCollectionSubscription = OrdersDittoCollectionSubscription(
            locationId = locationId
        ) { dittoProperties ->
            dittoProperties.map {
                it.toOrder()
            }
        }
        ordersSubscription = dittoStoreManager.startSubscription(
            dittoCollectionSubscription = ordersDittoCollectionSubscription
        )
    }

    fun ordersFlow(): Flow<List<Order>> {
        return ordersSubscription ?: flow {
            emptyList<Order>()
        }
    }
}
