package live.ditto.pos.core.domain.usecase

import live.ditto.pos.settings.AppSettings
import javax.inject.Inject

class AppConfigurationStateUseCase @Inject constructor(private val appSettings: AppSettings) {

    enum class AppConfigurationState {
        VALID,
        LOCATION_NEEDED
    }

    suspend operator fun invoke(): AppConfigurationState {
        return if (appSettings.locationId().isEmpty()) {
            AppConfigurationState.LOCATION_NEEDED
        } else {
            AppConfigurationState.VALID
        }
    }
}
