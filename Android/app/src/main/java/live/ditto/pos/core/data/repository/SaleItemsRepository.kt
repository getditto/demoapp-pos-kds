package live.ditto.pos.core.data.repository

import com.ditto.kotlin.Ditto
import com.ditto.kotlin.DittoSyncSubscription
import com.ditto.kotlin.DittoTransaction
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.mapLatest
import kotlinx.coroutines.flow.onEach
import live.ditto.ditto_wrapper.DittoManager
import live.ditto.pos.core.data.DocumentID
import live.ditto.pos.core.data.SaleItem
import live.ditto.pos.core.data.SaleItemCommands
import live.ditto.pos.core.data.SaleItemCreation
import live.ditto.pos.core.data.SaleItemMetadata
import live.ditto.pos.core.data.decodeOrSkip
import live.ditto.pos.core.data.demo.SeedStockMigration
import live.ditto.pos.core.data.observeAsFlow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SaleItemsRepository internal constructor(
    private val dittoProvider: () -> Ditto,
    locationIds: Flow<String>,
    repoScope: CoroutineScope
) {
    @Inject constructor(dittoManager: DittoManager, locationsRepository: LocationsRepository) : this(
        dittoProvider = dittoManager::requireDitto,
        locationIds = locationsRepository.locationIdFlow(),
        repoScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    )

    private val ditto: Ditto get() = dittoProvider()
    private var subscription: DittoSyncSubscription? = null

    init {
        locationIds
            .distinctUntilChanged()
            .onEach { locationId -> setActiveLocation(locationId.takeIf { it.isNotEmpty() }) }
            .launchIn(repoScope)
    }

    private fun setActiveLocation(locationId: String?) {
        subscription?.close()
        subscription = null
        if (locationId == null) return
        // Sync stays active across tabs; local query lifetimes belong to the visible UI.
        // https://docs.ditto.live/sdk/latest/crud/observing-data-changes
        subscription = ditto.sync.registerSubscription(
            """
                    SELECT * FROM ${SaleItem.COLLECTION_NAME}
                    WHERE _id.locationId = :locationId
            """.trimIndent(),
            mapOf("locationId" to locationId)
        )
    }

    private val catalogQuery = """
        SELECT * FROM sale_items
        WHERE _id.locationId = :locationId
        ORDER BY name, _id.id
    """.trimIndent()

    @OptIn(ExperimentalCoroutinesApi::class)
    fun observeLocationSaleItems(locationId: String): Flow<List<SaleItem>> =
        ditto.store.observeAsFlow<SaleItem>(catalogQuery, mapOf("locationId" to locationId))
            .mapLatest { items ->
                if (!SeedStockMigration.mayNeedUpgrade(items)) return@mapLatest items
                val prepared = ditto.store.transaction { transaction ->
                    SeedStockMigration.upgrade(locationId, transaction)
                    val current = transaction.execute(catalogQuery, mapOf("locationId" to locationId)) { it.decodeOrSkip<SaleItem>() }
                    DittoTransaction.Result.Commit(current)
                }
                (prepared as DittoTransaction.Result.Commit).value
            }
            .flowOn(Dispatchers.IO)

    suspend fun create(payload: SaleItemCreation) = SaleItemCommands.create(payload, ditto.store)
    suspend fun updateMetadata(metadata: SaleItemMetadata) = SaleItemCommands.updateMetadata(metadata, ditto.store)
    suspend fun increment(delta: Long, id: DocumentID) = SaleItemCommands.increment(delta, id, ditto.store)
    suspend fun restart(quantity: Long, id: DocumentID) = SaleItemCommands.restart(quantity, id, ditto.store)
}
