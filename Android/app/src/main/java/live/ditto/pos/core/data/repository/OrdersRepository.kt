package live.ditto.pos.core.data.repository

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import com.ditto.kotlin.Ditto
import com.ditto.kotlin.DittoSyncSubscription
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onEach
import kotlinx.datetime.TimeZone
import kotlinx.datetime.atStartOfDayIn
import kotlinx.datetime.toLocalDateTime
import live.ditto.ditto_wrapper.DittoManager
import live.ditto.pos.core.data.DocumentID
import live.ditto.pos.core.data.decodeOrSkip
import live.ditto.pos.core.data.dittoJsonString
import live.ditto.pos.core.data.observeAsFlow
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.data.orders.OrderEviction
import live.ditto.pos.core.data.orders.cartPathsForUnset
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
    repoScope: CoroutineScope
) {
    @Inject constructor(
        @ApplicationContext context: Context,
        dittoManager: DittoManager,
        locationsRepository: LocationsRepository
    ) : this(
        dittoProvider = dittoManager::requireDitto,
        locationIds = locationsRepository.locationIdFlow(),
        preferences = { context.getSharedPreferences(EVICTION_PREFS, Context.MODE_PRIVATE) },
        now = { Clock.System.now() },
        timeZone = TimeZone::currentSystemDefault,
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
        subscription = try {
            ditto.sync.registerSubscription(
                """
                    SELECT * FROM ${Order.COLLECTION_NAME}
                    WHERE _id.locationId = :locationId
                        AND createdAt > :TTL
                """.trimIndent(),
                mapOf("locationId" to locationId, "TTL" to startOfTodayIso())
            )
        } catch (error: Throwable) {
            reportSubscriptionFailure("subscribe orders", error)
        }
    }

    fun observeLocationOrders(locationId: String): Flow<List<Order>> =
        ditto.store.observeAsFlow(
            query = """
                SELECT * FROM ${Order.COLLECTION_NAME}
                WHERE _id.locationId = :locationId
                    AND createdAt > :TTL
            """.trimIndent(),
            args = mapOf("locationId" to locationId, "TTL" to startOfTodayIso())
        )

    suspend fun upsert(order: Order) {
        ditto.store.execute(
            """
                INSERT INTO ${Order.COLLECTION_NAME}
                DOCUMENTS (deserialize_json(:json))
                ON ID CONFLICT DO UPDATE_LOCAL_DIFF
            """.trimIndent(),
            mapOf("json" to order.dittoJsonString())
        )
    }

    // Restored carts must remain in the same date window as KDS and sync.
    suspend fun findRecentOrder(id: DocumentID): Order? = ditto.store.execute(
        "$CURRENT_ORDER_QUERY AND createdAt > :TTL",
        mapOf("id" to id.id, "locationId" to id.locationId, "TTL" to startOfTodayIso())
    ) { it.decodeOrSkip<Order>().firstOrNull() }

    fun observeOrder(id: DocumentID): Flow<Order?> = ditto.store.observeAsFlow<Order>(
        CURRENT_ORDER_QUERY,
        mapOf("id" to id.id, "locationId" to id.locationId)
    ).map { it.firstOrNull() }

    suspend fun clearCart(order: Order) {
        if (order.cart.isEmpty()) return
        // App-generated UUID paths need quoted identifiers, not DQL value arguments.
        // https://docs.ditto.live/dql/update
        val unsetList = order.cartPathsForUnset()
        ditto.store.execute(
            """
                UPDATE ${Order.COLLECTION_NAME}
                UNSET $unsetList
                WHERE _id.id = :id AND _id.locationId = :locationId
            """.trimIndent(),
            mapOf("id" to order.documentId.id, "locationId" to order.documentId.locationId)
        )
    }

    suspend fun reset(order: Order) {
        val createdAtNow = now().toDittoIsoString()
        val baseArgs = mapOf<String, Any>(
            "id" to order.documentId.id,
            "locationId" to order.documentId.locationId,
            "createdAt" to createdAtNow
        )
        val query = if (order.cart.isEmpty()) {
            """
                UPDATE ${Order.COLLECTION_NAME}
                SET createdAt = :createdAt
                WHERE _id.id = :id AND _id.locationId = :locationId
            """.trimIndent()
        } else {
            val unsetList = order.cartPathsForUnset()
            """
                UPDATE ${Order.COLLECTION_NAME}
                SET createdAt = :createdAt
                UNSET $unsetList
                WHERE _id.id = :id AND _id.locationId = :locationId
            """.trimIndent()
        }
        ditto.store.execute(query, baseArgs)
    }

    suspend fun runEvictionIfDue() {
        val prefs = preferences()
        val eviction = OrderEviction(
            now = now,
            timeZone = timeZone(),
            lastRun = { prefs.getLong(LAST_EVICTION_KEY, 0L) },
            recordRun = { prefs.edit().putLong(LAST_EVICTION_KEY, it).apply() },
            evict = { cutoff ->
                ditto.store.execute(
                    "EVICT FROM ${Order.COLLECTION_NAME} WHERE createdAt <= :TTL",
                    mapOf("TTL" to cutoff)
                )
            }
        )
        try {
            eviction.runIfDue()?.let { Log.i("Eviction", "evicted orders with createdAt <= $it") }
        } catch (error: Throwable) {
            Log.w("Eviction", error.message.orEmpty())
        }
    }

    private fun startOfTodayIso(): String =
        timeZone().let { zone -> now().toLocalDateTime(zone).date.atStartOfDayIn(zone).toDittoIsoString() }

    companion object {
        private const val CURRENT_ORDER_QUERY = "SELECT * FROM pos_orders WHERE _id.id = :id AND _id.locationId = :locationId"
        private const val EVICTION_PREFS = "ditto_pos_eviction"
        private const val LAST_EVICTION_KEY = "v2.lastEvictionAt"
    }
}
