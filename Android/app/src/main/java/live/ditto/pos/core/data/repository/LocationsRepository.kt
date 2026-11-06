package live.ditto.pos.core.data.repository

import com.ditto.kotlin.Ditto
import com.ditto.kotlin.DittoSyncSubscription
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
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
class LocationsRepository internal constructor(
    private val dittoProvider: () -> Ditto,
    private val appSettings: AppSettings,
    private val updateSyncGroup: suspend (String?) -> Unit,
    private val repoScope: CoroutineScope
) {
    @Inject constructor(dittoManager: DittoManager, appSettings: AppSettings) : this(
        dittoManager::requireDitto,
        appSettings,
        { locationId ->
            if (locationId != null) dittoManager.setSyncGroup(locationId) else dittoManager.resetSyncGroup()
        },
        CoroutineScope(SupervisorJob() + Dispatchers.IO)
    )

    private val ditto: Ditto get() = dittoProvider()
    private var subscription: DittoSyncSubscription? = null

    private val allLocations by lazy {
        ditto.store
            .observeAsFlow<Location>("SELECT * FROM ${Location.COLLECTION_NAME}")
            .map { locations -> locations.filter { it.id in LocationSeed.demoLocationIds } as List<Location>? }
            .stateIn(repoScope, SharingStarted.WhileSubscribed(stopTimeoutMillis = 0, replayExpirationMillis = 0), null)
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
        subscription = ditto.sync.registerSubscription(
            "SELECT * FROM ${Location.COLLECTION_NAME}"
        )
    }

    suspend fun setActiveLocation(locationId: String) {
        appSettings.setLocationId(locationId = locationId)
        updateSyncGroup(locationId.takeIf { it.isNotEmpty() })
    }

    fun locationIdFlow(): Flow<String> = appSettings.locationIdFlow()

    fun observeAllLocations(): StateFlow<List<Location>?> = allLocations

    fun currentLocationFlow(): Flow<Location?> =
        combine(locationIdFlow(), observeAllLocations()) { locationId, locations ->
            if (locationId.isEmpty()) null else locations?.firstOrNull { it.id == locationId }
        }
}
