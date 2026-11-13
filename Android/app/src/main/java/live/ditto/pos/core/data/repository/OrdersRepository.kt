package live.ditto.pos.core.data.repository

import android.content.Context
import android.content.SharedPreferences
import com.ditto.kotlin.Ditto
import com.ditto.kotlin.DittoSyncSubscription
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.mapLatest
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.atStartOfDayIn
import kotlinx.datetime.toLocalDateTime
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.decodeFromJsonElement
import live.ditto.ditto_wrapper.DittoManager
import live.ditto.pos.core.data.DocumentID
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.core.data.Payment
import live.ditto.pos.core.data.decodeOrSkip
import live.ditto.pos.core.data.demo.BundledFoodPhotos
import live.ditto.pos.core.data.demo.SeedImageMigration
import live.ditto.pos.core.data.demo.documentId
import live.ditto.pos.core.data.demo.hasLegacyOrderInput
import live.ditto.pos.core.data.dittoJson
import live.ditto.pos.core.data.observeAsFlow
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.data.orders.OrderCommands
import live.ditto.pos.core.data.orders.OrderEviction
import live.ditto.pos.core.data.toDittoIsoString
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.time.Clock
import kotlin.time.Instant

@Singleton
class OrdersRepository internal constructor(
    private val dittoProvider: () -> Ditto,
    locationIds: Flow<String>,
    private val preferences: () -> SharedPreferences,
    private val now: () -> Instant,
    private val timeZone: () -> TimeZone,
    repoScope: CoroutineScope,
    private val bundledPhotos: BundledFoodPhotos
) {
    @Inject constructor(
        @ApplicationContext context: Context,
        dittoManager: DittoManager,
        locationsRepository: LocationsRepository,
        bundledPhotos: BundledFoodPhotos
    ) : this(
        dittoProvider = dittoManager::requireDitto,
        locationIds = locationsRepository.locationIdFlow(),
        preferences = { context.getSharedPreferences(EVICTION_PREFS, Context.MODE_PRIVATE) },
        now = { Clock.System.now() },
        timeZone = TimeZone::currentSystemDefault,
        repoScope = CoroutineScope(SupervisorJob() + Dispatchers.IO),
        bundledPhotos = bundledPhotos
    )

    private val ditto: Ditto get() = dittoProvider()
    private var subscription: DittoSyncSubscription? = null
    private val subscriptionMutex = Mutex()
    private var activeLocationId: String? = null
    private var subscriptionCutoff = preferences().getLong(LAST_EVICTION_KEY, 0L).let { lastRun ->
        startOfDayIso(if (lastRun > 0) Instant.fromEpochMilliseconds(lastRun) else now())
    }

    init {
        locationIds
            .distinctUntilChanged()
            .onEach { locationId -> setActiveLocation(locationId.takeIf { it.isNotEmpty() }) }
            .launchIn(repoScope)
    }

    private suspend fun setActiveLocation(locationId: String?) = subscriptionMutex.withLock {
        activeLocationId = locationId
        refreshSubscription()
    }

    private fun refreshSubscription() {
        subscription?.close()
        subscription = null
        val locationId = activeLocationId ?: return
        subscription = ditto.sync.registerSubscription(
            """
                    SELECT * FROM ${Order.COLLECTION_NAME}
                    WHERE _id.locationId = :locationId
                        AND createdAt > :TTL
            """.trimIndent(),
            mapOf("locationId" to locationId, "TTL" to subscriptionCutoff)
        )
    }

    fun observeLocationOrders(locationId: String): Flow<List<Order>> =
        observePreparedOrders(
            query = """
                SELECT * FROM ${Order.COLLECTION_NAME}
                WHERE _id.locationId = :locationId
            """.trimIndent(),
            arguments = mapOf("locationId" to locationId)
        )

    suspend fun upsert(order: Order) {
        OrderCommands.upsert(order, ditto.store)
    }

    suspend fun addPayment(payment: Payment, paymentId: String, id: DocumentID) {
        OrderCommands.addPayment(payment, paymentId, id, ditto.store)
    }

    suspend fun updateStatus(status: OrderStatus, id: DocumentID) {
        OrderCommands.updateStatus(status, id, ditto.store)
    }

    suspend fun findOrder(id: DocumentID): Order? {
        SeedImageMigration(ditto.store, bundledPhotos).upgradeOrders(listOf(id))
        return ditto.store.execute(CURRENT_ORDER_QUERY, mapOf("id" to id.id, "locationId" to id.locationId)) {
            it.decodeOrSkip<Order>().firstOrNull()
        }
    }

    fun observeOrder(id: DocumentID): Flow<Order?> = observePreparedOrders(
        CURRENT_ORDER_QUERY,
        mapOf("id" to id.id, "locationId" to id.locationId)
    ).map { it.firstOrNull() }

    @OptIn(ExperimentalCoroutinesApi::class)
    private fun observePreparedOrders(query: String, arguments: Map<String, Any>): Flow<List<Order>> =
        ditto.store.observeAsFlow<JsonObject>(query, arguments).mapLatest { rows ->
            if (rows.hasLegacyOrderInput()) {
                SeedImageMigration(ditto.store, bundledPhotos).upgradeOrders(rows.mapNotNull { it.documentId() })
                ditto.store.execute(query, arguments) { it.decodeOrSkip<Order>() }
            } else {
                rows.mapNotNull { runCatching { dittoJson.decodeFromJsonElement<Order>(it) }.getOrNull() }
            }
        }.flowOn(Dispatchers.IO)

    suspend fun clearCart(order: Order) {
        OrderCommands.clearCart(order, ditto.store)
    }

    suspend fun runEvictionIfDue() {
        val prefs = preferences()
        val eviction = OrderEviction(
            now = now,
            timeZone = timeZone(),
            lastRun = { prefs.getLong(LAST_EVICTION_KEY, 0L) },
            recordRun = { prefs.edit().putLong(LAST_EVICTION_KEY, it).apply() },
            evict = { cutoff ->
                subscriptionMutex.withLock {
                    // An active subscription can fetch evicted documents again.
                    // https://docs.ditto.live/sdk/latest/crud/delete#evicting-data
                    subscription?.close()
                    subscription = null
                    try {
                        ditto.store.execute(
                            "EVICT FROM ${Order.COLLECTION_NAME} WHERE createdAt <= :TTL",
                            mapOf("TTL" to cutoff)
                        )
                        subscriptionCutoff = cutoff
                    } finally {
                        refreshSubscription()
                    }
                }
            }
        )
        eviction.runIfDue()
    }

    private fun startOfDayIso(instant: Instant): String =
        timeZone().let { zone -> instant.toLocalDateTime(zone).date.atStartOfDayIn(zone).toDittoIsoString() }

    companion object {
        private const val CURRENT_ORDER_QUERY = "SELECT * FROM pos_orders WHERE _id.id = :id AND _id.locationId = :locationId"
        private const val EVICTION_PREFS = "ditto_pos_eviction"
        private const val LAST_EVICTION_KEY = "v2.lastEvictionAt"
    }
}
