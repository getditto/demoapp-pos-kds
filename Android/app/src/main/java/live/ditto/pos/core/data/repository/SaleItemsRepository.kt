package live.ditto.pos.core.data.repository

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import live.ditto.Ditto
import live.ditto.DittoSyncSubscription
import live.ditto.ditto_wrapper.DittoManager
import live.ditto.pos.core.data.SaleItem
import live.ditto.pos.core.data.observeAsFlow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SaleItemsRepository @Inject constructor(
    private val dittoManager: DittoManager,
    private val locationsRepository: LocationsRepository
) {
    private val ditto: Ditto get() = dittoManager.requireDitto()
    private var subscription: DittoSyncSubscription? = null
    private val repoScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    init {
        locationsRepository.locationIdFlow()
            .filter { it.isNotEmpty() }
            .distinctUntilChanged()
            .onEach { locationId -> setActiveLocation(locationId) }
            .launchIn(repoScope)
    }

    private fun setActiveLocation(locationId: String) {
        subscription?.close()
        subscription = ditto.sync.registerSubscription(
            """
                SELECT * FROM ${SaleItem.COLLECTION_NAME}
                WHERE _id.locationId = :locationId
                ORDER BY name
            """.trimIndent(),
            mapOf("locationId" to locationId)
        )
    }

    fun observeLocationSaleItems(locationId: String): Flow<List<SaleItem>> =
        ditto.store.observeAsFlow(
            query = """
                SELECT * FROM ${SaleItem.COLLECTION_NAME}
                WHERE _id.locationId = :locationId
                ORDER BY name
            """.trimIndent(),
            args = mapOf("locationId" to locationId)
        )
}
