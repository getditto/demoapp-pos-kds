package live.ditto.pos.core.data.repository

import com.ditto.kotlin.Ditto
import com.ditto.kotlin.DittoSyncSubscription
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import live.ditto.ditto_wrapper.DittoManager
import live.ditto.pos.core.data.demo.LocationSeed
import live.ditto.pos.core.data.locations.Location
import live.ditto.pos.core.data.observeAsFlow
import live.ditto.pos.settings.AppSettings
import javax.inject.Inject
import javax.inject.Singleton

// Location selection is device-local so it cannot switch another demo device.
@Singleton
class LocationsRepository @Inject constructor(
    private val dittoManager: DittoManager,
    private val appSettings: AppSettings
) {
    private val ditto: Ditto get() = dittoManager.requireDitto()
    private var subscription: DittoSyncSubscription? = null
    private val repoScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private val allLocations by lazy {
        ditto.store
            .observeAsFlow<Location>("SELECT * FROM ${Location.COLLECTION_NAME}")
            .map { locations -> locations.filter { it.id in LocationSeed.demoLocationIds } }
            .stateIn(repoScope, SharingStarted.WhileSubscribed(STOP_TIMEOUT_MILLIS), emptyList())
    }

    init {
        // Retired custom-location IDs must not bypass setup.
        repoScope.launch {
            val saved = appSettings.locationId()
            if (saved.isNotEmpty()) {
                if (saved in LocationSeed.demoLocationIds) {
                    setActiveLocation(saved)
                } else {
                    setActiveLocation("")
                }
            }
        }
    }

    fun startSubscription() {
        if (subscription != null) return
        subscription = try {
            ditto.sync.registerSubscription(
                "SELECT * FROM ${Location.COLLECTION_NAME}"
            )
        } catch (error: Throwable) {
            reportSubscriptionFailure("subscribe locations", error)
        }
    }

    suspend fun setActiveLocation(locationId: String) {
        appSettings.setLocationId(locationId = locationId)
        if (locationId.isNotEmpty()) {
            dittoManager.setSyncGroup(locationId)
        } else {
            dittoManager.resetSyncGroup()
        }
    }

    fun locationIdFlow(): Flow<String> = appSettings.locationIdFlow()

    fun observeAllLocations(): Flow<List<Location>> = allLocations

    fun currentLocationFlow(): Flow<Location?> =
        combine(locationIdFlow(), observeAllLocations()) { locationId, locations ->
            if (locationId.isEmpty()) null else locations.firstOrNull { it.id == locationId }
        }

    private companion object {
        const val STOP_TIMEOUT_MILLIS = 0L
    }
}
