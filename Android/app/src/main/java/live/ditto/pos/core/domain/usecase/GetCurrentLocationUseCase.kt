package live.ditto.pos.core.domain.usecase

import kotlinx.coroutines.flow.first
import live.ditto.pos.core.data.demo.LocationSeed
import live.ditto.pos.core.data.locations.Location
import live.ditto.pos.core.domain.repository.DittoRepository
import live.ditto.pos.core.domain.usecase.AppConfigurationStateUseCase.AppConfigurationState
import live.ditto.pos.settings.AppSettings
import javax.inject.Inject

class GetCurrentLocationUseCase @Inject constructor(
    private val appSettings: AppSettings,
    private val dittoRepository: DittoRepository,
    private val appConfigurationStateUseCase: AppConfigurationStateUseCase,
    private val isUsingDemoLocationsUseCase: IsUsingDemoLocationsUseCase
) {

    suspend operator fun invoke(): Location? {
        val appConfigurationState = appConfigurationStateUseCase()

        return if (appConfigurationState == AppConfigurationState.VALID) {
            val locationId = appSettings.locationId()
            if (isUsingDemoLocationsUseCase()) {
                LocationSeed.demoLocations.find { it.id == locationId }
            } else {
                dittoRepository.observeAllLocations().first().find { it.id == locationId }
            }
        } else {
            null
        }
    }
}
