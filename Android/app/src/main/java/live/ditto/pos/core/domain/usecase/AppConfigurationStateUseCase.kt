package live.ditto.pos.core.domain.usecase

import live.ditto.pos.settings.AppSettings
import javax.inject.Inject

class AppConfigurationStateUseCase @Inject constructor(private val appSettings: AppSettings) {

    enum class AppConfigurationState {
        VALID,
        LOCATION_NEEDED,
        DEMO_OR_CUSTOM_LOCATION_NEEDED
    }

    suspend operator fun invoke(): AppConfigurationState {
        val isUsingDemoLocations = appSettings.isUsingDemoLocations()
        val locationId = appSettings.locationId()
        return if (isUsingDemoLocations != null) {
            if (locationId.isEmpty()) {
                AppConfigurationState.LOCATION_NEEDED
            } else {
                AppConfigurationState.VALID
            }
        } else {
            AppConfigurationState.DEMO_OR_CUSTOM_LOCATION_NEEDED
        }
    }
}
