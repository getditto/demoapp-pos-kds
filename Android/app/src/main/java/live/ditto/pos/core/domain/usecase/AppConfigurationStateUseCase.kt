package live.ditto.pos.core.domain.usecase

import live.ditto.pos.core.data.demo.LocationSeed
import live.ditto.pos.settings.AppSettings
import javax.inject.Inject

class AppConfigurationStateUseCase @Inject constructor(private val appSettings: AppSettings) {

    enum class AppConfigurationState {
        VALID,
        LOCATION_NEEDED
    }

    suspend operator fun invoke(): AppConfigurationState {
        // A location is only valid if it's one of the seven demo locations.
        // An empty id (never picked) or a stale/broken id (e.g. a legacy custom
        // location that no longer exists) both force the location picker.
        return if (appSettings.locationId() in LocationSeed.demoLocationIds) {
            AppConfigurationState.VALID
        } else {
            AppConfigurationState.LOCATION_NEEDED
        }
    }
}
