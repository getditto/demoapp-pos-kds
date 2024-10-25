package live.ditto.pos.core.domain.usecase

import live.ditto.pos.core.domain.repository.CoreRepository
import javax.inject.Inject

class AppConfigurationStateUseCase @Inject constructor(private val coreRepository: CoreRepository) {

    enum class AppConfigurationState {
        VALID,
        LOCATION_NEEDED,
        DEMO_OR_CUSTOM_LOCATION_NEEDED
    }

    suspend operator fun invoke(): AppConfigurationState {
        val isUsingDemoLocations = coreRepository.isUsingDemoLocations()
        val locationId = coreRepository.locationId()
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
