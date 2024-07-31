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
    }

    suspend fun isUsingDemoLocations(): Boolean {
        return context.dataStore.data
            .map { preferences ->
                preferences[usingDemoLocationsKey] ?: false
            }.first()
    }

    suspend fun shouldUseDemoLocations(useDemoLocations: Boolean) {
        context.dataStore.edit { settings ->
            settings[usingDemoLocationsKey] = useDemoLocations
        }
    }

    suspend fun locationId(): String {
        return context.dataStore.data
            .map { preferences ->
                preferences[locationIdKey]
            }.first() ?: ""
    }

    suspend fun setLocationId(locationId: String) {
        context.dataStore.edit { settings ->
            settings[locationIdKey] = locationId
        }
    }
}
