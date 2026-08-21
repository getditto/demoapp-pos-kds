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

/**
 * Owns the `locations` collection and the active-location state.
 * `setActiveLocation` is the only writer — it persists to [AppSettings] and
 * applies [DittoManager]'s sync group. Other per-collection repositories
 * subscribe to `locationIdFlow()` and re-register their own subscriptions
 * when it emits. Mirrors iOS `LocationsRepository`.
 */
@Singleton
class LocationsRepository @Inject constructor(
    private val dittoManager: DittoManager,
    private val appSettings: AppSettings
) {
    private val ditto: Ditto get() = dittoManager.requireDitto()
    private var subscription: DittoSyncSubscription? = null
    private val repoScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    /**
     * One shared observer on `locations`, mirroring iOS's single `allLocations`
     * publisher. `by lazy` so `requireDitto()` isn't touched at injection time,
     * and `stateIn` so every consumer replays the latest list off one observer
     * instead of opening its own.
     */
    private val allLocations by lazy {
        ditto.store
            .observeAsFlow<Location>("SELECT * FROM ${Location.COLLECTION_NAME}")
            .map { locations -> locations.filter { it.id in LocationSeed.demoLocationIds } }
            .stateIn(repoScope, SharingStarted.WhileSubscribed(STOP_TIMEOUT_MILLIS), emptyList())
    }

    init {
        // Restore the persisted active location on first injection (mirrors
        // iOS) — but only if it's still one of the seven demo locations. A
        // stale id (e.g. a legacy custom location that no longer exists) is
        // cleared so the user is forced to re-pick, and the sync group is reset
        // to default. The sync group applies as part of `setActiveLocation`.
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

    /**
     * Switch the active location. Persists, applies the sync group, and downstream
     * repositories react via `locationIdFlow()`. Pass an empty string to clear
     * the selection and reset the sync group back to default.
     */
    suspend fun setActiveLocation(locationId: String) {
        appSettings.setLocationId(locationId = locationId)
        if (locationId.isNotEmpty()) {
            dittoManager.setSyncGroup(locationId)
        } else {
            dittoManager.resetSyncGroup()
        }
    }

    /** Reactive stream of the active location id. Empty string when not set. */
    fun locationIdFlow(): Flow<String> = appSettings.locationIdFlow()

    fun observeAllLocations(): Flow<List<Location>> = allLocations

    /**
     * The active location resolved against the synced `locations` collection.
     * Null when nothing is selected, or when the saved id isn't one of the demo
     * locations — [observeAllLocations] already filters to those, so no separate
     * validity check is needed. Mirrors iOS `LocationsRepository.currentLocation`.
     */
    fun currentLocationFlow(): Flow<Location?> =
        combine(locationIdFlow(), observeAllLocations()) { locationId, locations ->
            if (locationId.isEmpty()) null else locations.firstOrNull { it.id == locationId }
        }

    private companion object {
        const val STOP_TIMEOUT_MILLIS = 5_000L
    }
}
