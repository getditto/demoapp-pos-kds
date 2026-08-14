package live.ditto.pos.core.data.repository

import android.content.Context
import android.util.Log
import com.ditto.kotlin.Ditto
import com.ditto.kotlin.DittoSyncSubscription
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.atStartOfDayIn
import kotlinx.datetime.toLocalDateTime
import live.ditto.ditto_wrapper.DittoManager
import live.ditto.pos.core.data.dittoJsonString
import live.ditto.pos.core.data.observeAsFlow
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.data.toDittoIsoString
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class OrdersRepository @Inject constructor(
    @ApplicationContext private val context: Context,
    private val dittoManager: DittoManager,
    private val locationsRepository: LocationsRepository
) {
    private val ditto: Ditto get() = dittoManager.requireDitto()
    private var subscription: DittoSyncSubscription? = null
    private val repoScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    init {
        // Pull the active location from LocationsRepository and re-register
        // the subscription on every change. Mirrors iOS.
        locationsRepository.locationIdFlow()
            .filter { it.isNotEmpty() }
            .distinctUntilChanged()
            .onEach { locationId -> setActiveLocation(locationId) }
            .launchIn(repoScope)
    }

    private fun setActiveLocation(locationId: String) {
        subscription?.close()
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

    suspend fun clearCart(order: Order) {
        if (order.cart.isEmpty()) return
        // UNSET target paths can't be parameterized in DQL, so the cart keys
        // (app-generated line-item UUIDs) are interpolated; all values use :named args.
        val unsetList = order.cart.keys.joinToString(", ") { "cart.\"$it\"" }
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
        val createdAtNow = Clock.System.now().toDittoIsoString()
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
            val unsetList = order.cart.keys.joinToString(", ") { "cart.\"$it\"" }
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
        val prefs = context.getSharedPreferences(EVICTION_PREFS, Context.MODE_PRIVATE)
        val now = Clock.System.now().toEpochMilliseconds()
        val last = prefs.getLong(LAST_EVICTION_KEY, 0L)
        if (now - last < TWENTY_FOUR_HOURS_MILLIS) return

        val ttl = startOfTodayIso()
        try {
            ditto.store.execute(
                "EVICT FROM ${Order.COLLECTION_NAME} WHERE createdAt <= :TTL",
                mapOf("TTL" to ttl)
            )
            prefs.edit().putLong(LAST_EVICTION_KEY, now).apply()
            Log.i("Eviction", "evicted orders with createdAt <= $ttl")
        } catch (error: Throwable) {
            Log.w("Eviction", error.message.orEmpty())
        }
    }

    companion object {
        private const val TWENTY_FOUR_HOURS_MILLIS = 24L * 60 * 60 * 1000
        private const val EVICTION_PREFS = "ditto_pos_eviction"
        private const val LAST_EVICTION_KEY = "v2.lastEvictionAt"
    }
}

private fun startOfTodayIso(): String {
    val tz = TimeZone.currentSystemDefault()
    return Clock.System.now().toLocalDateTime(tz).date.atStartOfDayIn(tz).toDittoIsoString()
}
