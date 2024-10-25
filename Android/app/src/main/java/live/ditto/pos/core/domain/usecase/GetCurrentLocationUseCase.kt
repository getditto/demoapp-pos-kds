package live.ditto.pos.core.domain.usecase

import live.ditto.pos.core.data.demoLocations
import live.ditto.pos.core.data.locations.Location
import live.ditto.pos.core.domain.repository.CoreRepository
import live.ditto.pos.core.domain.repository.DittoRepository
import live.ditto.pos.core.domain.usecase.AppConfigurationStateUseCase.AppConfigurationState
import javax.inject.Inject

class GetCurrentLocationUseCase @Inject constructor(
    private val coreRepository: CoreRepository,
    private val dittoRepository: DittoRepository,
    private val appConfigurationStateUseCase: AppConfigurationStateUseCase,
    private val isUsingDemoLocationsUseCase: IsUsingDemoLocationsUseCase
) {

    suspend operator fun invoke(): Location? {
        val appConfigurationState = appConfigurationStateUseCase()

        return if (appConfigurationState == AppConfigurationState.VALID) {
            val locationId = coreRepository.locationId()
            if (isUsingDemoLocationsUseCase()) {
                demoLocations.find {
                    it.id == locationId
                }
            } else {
                dittoRepository.getLocationById(locationId = locationId)
            }
        } else {
            null
        }
    }
}
