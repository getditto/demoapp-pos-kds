package live.ditto.pos.settings

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

private const val DATA_STORE_NAME = "settings"

/**
 * Device-local app preferences backed by Android DataStore. Not synced via
 * Ditto — the per-collection repositories in `core.data.repository` own
 * synced data. The two are kept in separate packages so the boundary
 * between "local-only" and "synced" is visible at the import line. Mirrors
 * iOS `Settings` (`iOS/DittoPOS/Settings/`).
 */
@Singleton
class AppSettings @Inject constructor(
    @ApplicationContext private val context: Context
) {

    companion object {
        private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = DATA_STORE_NAME)
        private val locationIdKey = stringPreferencesKey("location_id")
        private val currentOrderId = stringPreferencesKey("current_order_id")
    }

    suspend fun locationId(): String {
        return getStringPreference(locationIdKey)
    }

    /**
     * Reactive stream of the current location id. Empty string when not set.
     * View models should `flatMapLatest` on this to switch their Ditto
     * observers when the user picks a different location.
     */
    fun locationIdFlow(): Flow<String> =
        context.dataStore.data
            .map { it[locationIdKey] ?: "" }
            .distinctUntilChanged()

    suspend fun setLocationId(locationId: String) {
        setPreferences(locationIdKey, locationId)
    }

    suspend fun currentOrderId(): String {
        return getStringPreference(currentOrderId)
    }

    suspend fun setCurrentOrderId(orderId: String) {
        setPreferences(currentOrderId, orderId)
    }

    private suspend fun getStringPreference(
        preferencesKey: Preferences.Key<String>,
        defaultValue: String = ""
    ): String {
        return context.dataStore.data
            .map { preferences ->
                preferences[preferencesKey]
            }.first() ?: defaultValue
    }

    private suspend fun <T> setPreferences(
        preferencesKey: Preferences.Key<T>,
        value: T
    ) {
        context.dataStore.edit { settings ->
            settings[preferencesKey] = value
        }
    }
}
