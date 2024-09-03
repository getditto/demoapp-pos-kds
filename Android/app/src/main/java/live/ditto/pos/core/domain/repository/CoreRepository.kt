package live.ditto.pos.core.domain.repository

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

private const val DATA_STORE_NAME = "settings"

@Singleton
class CoreRepository @Inject constructor(
    @ApplicationContext private val context: Context
) {

    companion object {
        private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = DATA_STORE_NAME)
        private val usingDemoLocationsKey = booleanPreferencesKey("using_demo_locations")
        private val locationIdKey = stringPreferencesKey("location_id")
        private val currentOrderId = stringPreferencesKey("current_order_id")
    }

    suspend fun isUsingDemoLocations(): Boolean {
        return getBooleanPreference(usingDemoLocationsKey)
    }

    suspend fun shouldUseDemoLocations(useDemoLocations: Boolean) {
        setPreferences(usingDemoLocationsKey, useDemoLocations)
    }

    suspend fun locationId(): String {
        return getStringPreference(locationIdKey)
    }

    suspend fun setLocationId(locationId: String) {
        setPreferences(locationIdKey, locationId)
    }

    suspend fun currentOrderId(): String {
        return getStringPreference(currentOrderId)
    }

    suspend fun setCurrentOrderId(orderId: String) {
        setPreferences(currentOrderId, orderId)
    }

    private suspend fun getBooleanPreference(
        preferencesKey: Preferences.Key<Boolean>,
        defaultValue: Boolean = false
    ): Boolean {
        return context.dataStore.data
            .map { preferences ->
                preferences[preferencesKey] ?: defaultValue
            }.first()
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
