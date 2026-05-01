package live.ditto.pos.core.domain.repository

import android.content.Context
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.channels.trySendBlocking
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.buffer
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.map
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.atStartOfDayIn
import kotlinx.datetime.toLocalDateTime
import kotlinx.serialization.encodeToString
import live.ditto.Ditto
import live.ditto.DittoSyncSubscription
import live.ditto.ditto_wrapper.DittoManager
import live.ditto.pos.core.data.SaleItem
import live.ditto.pos.core.data.demo.DemoSeeder
import live.ditto.pos.core.data.dittoJson
import live.ditto.pos.core.data.locations.Location
import live.ditto.pos.core.data.orders.Order
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class DittoRepository @Inject constructor(
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
                    AND createdOn > :TTL
            """.trimIndent(),
            args = mapOf("locationId" to locationId, "TTL" to startOfTodayIso())
        )
        registerSub(
            key = "sale_items",
            query = """
                SELECT * FROM ${SaleItem.COLLECTION_NAME}
                WHERE _id.locationId = :locationId
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
        observeJsonStrings("SELECT * FROM ${Location.COLLECTION_NAME}")
            .map { jsons -> jsons.mapNotNull { decodeOrNull<Location>(it) } }

    fun observeLocationOrders(locationId: String): Flow<List<Order>> =
        observeJsonStrings(
            query = """
                SELECT * FROM ${Order.COLLECTION_NAME}
                WHERE _id.locationId = :locationId
                    AND createdOn > :TTL
            """.trimIndent(),
            args = mapOf("locationId" to locationId, "TTL" to startOfTodayIso())
        ).map { jsons -> jsons.mapNotNull { decodeOrNull<Order>(it) } }

    fun observeLocationSaleItems(locationId: String): Flow<List<SaleItem>> =
        observeJsonStrings(
            query = """
                SELECT * FROM ${SaleItem.COLLECTION_NAME}
                WHERE _id.locationId = :locationId
            """.trimIndent(),
            args = mapOf("locationId" to locationId)
        ).map { jsons -> jsons.mapNotNull { decodeOrNull<SaleItem>(it) } }

    private fun observeJsonStrings(
        query: String,
        args: Map<String, Any> = emptyMap()
    ): Flow<List<String>> = callbackFlow {
        val observer = ditto.store.registerObserver(query, args) { result ->
            trySendBlocking(result.items.map { it.jsonString() })
        }
        awaitClose { observer.close() }
    }.buffer(Channel.UNLIMITED)

    // ----- Mutations -----

    suspend fun upsertOrder(order: Order) {
        ditto.store.execute(
            """
            INSERT INTO ${Order.COLLECTION_NAME}
            DOCUMENTS (deserialize_json(:json))
            ON ID CONFLICT DO UPDATE_LOCAL_DIFF
            """.trimIndent(),
            mapOf("json" to dittoJson.encodeToString(order))
        )
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
            mapOf("id" to order.id, "locationId" to order.locationId)
        )
    }

    suspend fun resetOrder(order: Order) {
        val createdOnNow = isoNow()
        val baseArgs = mapOf<String, Any>(
            "id" to order.id,
            "locationId" to order.locationId,
            "createdOn" to createdOnNow
        )
        if (order.cart.isEmpty()) {
            ditto.store.execute(
                """
                UPDATE ${Order.COLLECTION_NAME}
                SET createdOn = :createdOn
                WHERE _id.id = :id AND _id.locationId = :locationId
                """.trimIndent(),
                baseArgs
            )
        } else {
            val unsetList = order.cart.keys.joinToString(", ") { "cart.\"$it\"" }
            ditto.store.execute(
                """
                UPDATE ${Order.COLLECTION_NAME}
                SET createdOn = :createdOn
                UNSET $unsetList
                WHERE _id.id = :id AND _id.locationId = :locationId
                """.trimIndent(),
                baseArgs
            )
        }
    }

    suspend fun insertCustomLocation(location: Location) {
        ditto.store.execute(
            """
            INSERT INTO ${Location.COLLECTION_NAME}
            DOCUMENTS (deserialize_json(:json))
            ON ID CONFLICT DO UPDATE_LOCAL_DIFF
            """.trimIndent(),
            mapOf("json" to dittoJson.encodeToString(location))
        )
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

        try {
            ditto.store.execute(
                "EVICT FROM ${Order.COLLECTION_NAME} WHERE createdOn <= :TTL",
                mapOf("TTL" to startOfTodayIso())
            )
            prefs.edit().putLong(LAST_EVICTION_KEY, now).apply()
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

private inline fun <reified T> decodeOrNull(json: String): T? =
    runCatching { dittoJson.decodeFromString<T>(json) }.getOrNull()

private fun isoNow(): String = Clock.System.now().toString()

private fun startOfTodayIso(): String {
    val tz = TimeZone.currentSystemDefault()
    return Clock.System.now().toLocalDateTime(tz).date.atStartOfDayIn(tz).toString()
}
