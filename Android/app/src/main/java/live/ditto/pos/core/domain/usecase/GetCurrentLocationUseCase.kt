package live.ditto.pos.core.domain.usecase

import live.ditto.pos.core.data.demo.LocationSeed
import live.ditto.pos.core.data.locations.Location
import live.ditto.pos.core.domain.usecase.AppConfigurationStateUseCase.AppConfigurationState
import live.ditto.pos.settings.AppSettings
import javax.inject.Inject

class GetCurrentLocationUseCase @Inject constructor(
    private val appSettings: AppSettings,
    private val appConfigurationStateUseCase: AppConfigurationStateUseCase
) {

    suspend operator fun invoke(): Location? {
        if (appConfigurationStateUseCase() != AppConfigurationState.VALID) return null
        val locationId = appSettings.locationId()
        return LocationSeed.demoLocations.find { it.id == locationId }
    }
}
