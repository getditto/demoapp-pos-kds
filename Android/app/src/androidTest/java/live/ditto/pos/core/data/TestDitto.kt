package live.ditto.pos.core.data

import android.app.Application
import android.content.Context
import android.content.SharedPreferences
import androidx.datastore.preferences.core.PreferenceDataStoreFactory
import androidx.test.platform.app.InstrumentationRegistry
import com.ditto.kotlin.Ditto
import com.ditto.kotlin.DittoConfig
import com.ditto.kotlin.DittoFactory
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.job
import kotlinx.datetime.TimeZone
import live.ditto.pos.core.data.demo.BundledFoodPhotos
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.data.repository.LocationsRepository
import live.ditto.pos.core.data.repository.OrdersRepository
import live.ditto.pos.core.data.repository.SaleItemsRepository
import live.ditto.pos.settings.AppSettings
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import java.io.File
import java.util.UUID
import kotlin.time.Instant

internal class TestDitto(
    val ditto: Ditto,
    val preferences: SharedPreferences,
    private val scope: CoroutineScope,
    private val directory: File
) {
    val bundledPhotos = BundledFoodPhotos(InstrumentationRegistry.getInstrumentation().targetContext)

    val settings: AppSettings by lazy {
        AppSettings(PreferenceDataStoreFactory.create(scope = scope, produceFile = { File(directory, "ui.preferences_pb") }))
    }

    fun catalog(locationIds: Flow<String> = emptyFlow()): SaleItemsRepository = SaleItemsRepository({ ditto }, locationIds, scope, bundledPhotos)
    fun locations(updateSyncGroup: suspend (String?) -> Unit): LocationsRepository = LocationsRepository({ ditto }, settings, updateSyncGroup, scope)

    fun repository(now: Instant = Instant.parse("2026-04-01T12:00:00.000Z"), locationIds: Flow<String> = emptyFlow(), clock: () -> Instant = { now }): OrdersRepository = OrdersRepository(
        dittoProvider = { ditto },
        locationIds = locationIds,
        preferences = { preferences },
        now = clock,
        timeZone = { TimeZone.UTC },
        repoScope = scope,
        bundledPhotos = bundledPhotos
    )

    suspend fun insert(order: Order) {
        ditto.store.execute(
            "INSERT INTO pos_orders DOCUMENTS (deserialize_json(:json))",
            mapOf("json" to order.dittoJsonString())
        )
    }

    suspend fun read(id: DocumentID): Order = ditto.store.execute(
        "SELECT * FROM pos_orders WHERE _id.id = :id AND _id.locationId = :locationId",
        mapOf("id" to id.id, "locationId" to id.locationId)
    ) { it.decode<Order>().single() }

    companion object {
        fun fixture(): Order {
            val assets = InstrumentationRegistry.getInstrumentation().context.assets
            return assets.open("order.json").bufferedReader().use { dittoJson.decodeFromString(it.readText()) }
        }

        suspend fun <T> withInstance(block: suspend TestDitto.() -> T): T {
            val context = InstrumentationRegistry.getInstrumentation().targetContext
            assertEquals(Application::class.java, context.applicationContext.javaClass)
            val id = UUID.randomUUID().toString()
            val directory = File(context.cacheDir, "ditto-test-$id")
            val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
            val config = DittoConfig(
                databaseId = id,
                connect = DittoConfig.Connect.SmallPeersOnly(),
                persistenceDirectory = directory.absolutePath
            )
            assertNull(config.encryptionKey)
            assertNull((config.connect as DittoConfig.Connect.SmallPeersOnly).privateKey)
            try {
                return DittoFactory.create(config, scope).use { ditto ->
                    assertFalse(ditto.isActivated)
                    assertFalse(ditto.sync.isActive)
                    try {
                        TestDitto(ditto, context.getSharedPreferences(id, Context.MODE_PRIVATE), scope, directory).block()
                    } finally {
                        assertFalse("Tests must never start sync", ditto.sync.isActive)
                    }
                }
            } finally {
                scope.coroutineContext.job.cancelAndJoin()
                context.deleteSharedPreferences(id)
                directory.deleteRecursively()
            }
        }
    }
}
