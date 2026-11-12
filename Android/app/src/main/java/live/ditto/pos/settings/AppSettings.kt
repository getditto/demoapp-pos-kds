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

// A device's selected location/cart must not change another demo device's selection.
@Singleton
class AppSettings internal constructor(
    private val store: DataStore<Preferences>
) {
    @Inject constructor(@ApplicationContext context: Context) : this(context.dataStore)

    companion object {
        private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = DATA_STORE_NAME)
        private val locationIdKey = stringPreferencesKey("location_id")
        private val currentOrderId = stringPreferencesKey("current_order_id")
        private val appearanceKey = stringPreferencesKey("appearance")
    }

    suspend fun locationId(): String = getStringPreference(locationIdKey)

    fun locationIdFlow(): Flow<String> =
        store.data
            .map { it[locationIdKey] ?: "" }
            .distinctUntilChanged()

    suspend fun setLocationId(locationId: String) {
        setPreferences(locationIdKey, locationId)
    }

    suspend fun currentOrderId(): String = getStringPreference(currentOrderId)

    suspend fun setCurrentOrderId(orderId: String) {
        setPreferences(currentOrderId, orderId)
    }

    fun appearanceFlow(): Flow<AppAppearance> = store.data
        .map { preferences ->
            AppAppearance.entries.firstOrNull { it.name == preferences[appearanceKey] } ?: AppAppearance.SYSTEM
        }
        .distinctUntilChanged()

    suspend fun setAppearance(appearance: AppAppearance) {
        setPreferences(appearanceKey, appearance.name)
    }

    private suspend fun getStringPreference(
        preferencesKey: Preferences.Key<String>,
        defaultValue: String = ""
    ): String = store.data
        .map { preferences ->
            preferences[preferencesKey]
        }.first() ?: defaultValue

    private suspend fun <T> setPreferences(
        preferencesKey: Preferences.Key<T>,
        value: T
    ) {
        store.edit { settings ->
            settings[preferencesKey] = value
        }
    }
}
