package live.ditto.pos.core.domain.repository

import android.content.Context
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.atStartOfDayIn
import kotlinx.datetime.toLocalDateTime
import live.ditto.Ditto
import live.ditto.DittoSyncSubscription
import live.ditto.ditto_wrapper.DittoManager
import live.ditto.pos.core.data.SaleItem
import live.ditto.pos.core.data.demo.DemoSeeder
import live.ditto.pos.core.data.dittoJsonString
import live.ditto.pos.core.data.locations.Location
import live.ditto.pos.core.data.observeAsFlow
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.data.toDittoIsoString
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class DittoRepository
@Inject
constructor(
    @ApplicationContext private val context: Context,
    private val dittoManager: DittoManager
) {
    private val ditto: Ditto get() = dittoManager.requireDitto()
    private val activeSubs = mutableMapOf<String, DittoSyncSubscription>()

    fun requireDitto(): Ditto = ditto

    fun refreshPermissions() {
        ditto.refreshPermissions()
    }

    fun getMissingPermissions(): Array<String> = dittoManager.missingPermissions()

    // ----- Subscriptions -----

    fun startLocationsSubscription() {
        registerSub(
            key = "locations",
            query = "SELECT * FROM ${Location.COLLECTION_NAME}"
        )
    }

    fun setActiveLocation(locationId: String) {
        registerSub(
            key = "orders",
            query = """
                    SELECT * FROM ${Order.COLLECTION_NAME}
                    WHERE _id.locationId = :locationId
                        AND createdAt > :TTL
            """.trimIndent(),
            args = mapOf("locationId" to locationId, "TTL" to startOfTodayIso())
        )
        registerSub(
            key = "sale_items",
            query = """
                    SELECT * FROM ${SaleItem.COLLECTION_NAME}
                    WHERE _id.locationId = :locationId
                    ORDER BY name
            """.trimIndent(),
            args = mapOf("locationId" to locationId)
        )
    }

    private fun registerSub(key: String, query: String, args: Map<String, Any> = emptyMap()) {
        activeSubs[key]?.close()
        activeSubs[key] = ditto.sync.registerSubscription(query, args)
    }

    // ----- Observers -----

    fun observeAllLocations(): Flow<List<Location>> =
        ditto.store.observeAsFlow("SELECT * FROM ${Location.COLLECTION_NAME}")

    fun observeLocationOrders(locationId: String): Flow<List<Order>> =
        ditto.store.observeAsFlow(
            query = """
                    SELECT * FROM ${Order.COLLECTION_NAME}
                    WHERE _id.locationId = :locationId
                        AND createdAt > :TTL
            """.trimIndent(),
            args = mapOf("locationId" to locationId, "TTL" to startOfTodayIso())
        )

    fun observeLocationSaleItems(locationId: String): Flow<List<SaleItem>> =
        ditto.store.observeAsFlow(
            query = """
                    SELECT * FROM ${SaleItem.COLLECTION_NAME}
                    WHERE _id.locationId = :locationId
                    ORDER BY name
            """.trimIndent(),
            args = mapOf("locationId" to locationId)
        )

    // ----- Mutations -----

    suspend fun upsertOrder(order: Order) {
        ditto.store.execute(
            """
                INSERT INTO ${Order.COLLECTION_NAME}
                DOCUMENTS (deserialize_json(:json))
                ON ID CONFLICT DO UPDATE_LOCAL_DIFF
            """.trimIndent(),
            mapOf("json" to order.dittoJsonString())
        ).use { }
    }

    suspend fun clearCart(order: Order) {
        if (order.cart.isEmpty()) return
        val unsetList = order.cart.keys.joinToString(", ") { "cart.\"$it\"" }
        ditto.store.execute(
            """
                UPDATE ${Order.COLLECTION_NAME}
                UNSET $unsetList
                WHERE _id.id = :id AND _id.locationId = :locationId
            """.trimIndent(),
            mapOf("id" to order.documentId.id, "locationId" to order.documentId.locationId)
        ).use { }
    }

    suspend fun resetOrder(order: Order) {
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
        ditto.store.execute(query, baseArgs).use { }
    }

    suspend fun insertCustomLocation(location: Location) {
        ditto.store.execute(
            """
                INSERT INTO ${Location.COLLECTION_NAME}
                DOCUMENTS (deserialize_json(:json))
                ON ID CONFLICT DO UPDATE_LOCAL_DIFF
            """.trimIndent(),
            mapOf("json" to location.dittoJsonString())
        ).use { }
    }

    // ----- Lifecycle -----

    suspend fun seedAll() {
        DemoSeeder(ditto).seedAll()
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
            ).use { }
            prefs.edit().putLong(LAST_EVICTION_KEY, now).apply()
            android.util.Log.i("Eviction", "evicted orders with createdAt <= $ttl")
        } catch (error: Throwable) {
            android.util.Log.w("Eviction", error.message.orEmpty())
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
