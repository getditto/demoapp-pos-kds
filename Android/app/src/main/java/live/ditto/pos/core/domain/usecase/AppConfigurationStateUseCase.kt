package live.ditto.pos.core.domain.usecase

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import live.ditto.pos.core.data.demo.LocationSeed
import live.ditto.pos.settings.AppSettings
import javax.inject.Inject

/**
 * Whether the app is configured enough to leave the location picker, emitted on
 * every change to the persisted location id.
 */
class AppConfigurationStateUseCase @Inject constructor(private val appSettings: AppSettings) {

    enum class AppConfigurationState {
        VALID,
        LOCATION_NEEDED
    }

    operator fun invoke(): Flow<AppConfigurationState> =
        appSettings.locationIdFlow().map { locationId ->
            // A location is only valid if it's one of the seven demo locations.
            // An empty id (never picked) or a stale/broken id (e.g. a legacy custom
            // location that no longer exists) both force the location picker.
            if (locationId in LocationSeed.demoLocationIds) {
                AppConfigurationState.VALID
            } else {
                AppConfigurationState.LOCATION_NEEDED
            }
        }
}
