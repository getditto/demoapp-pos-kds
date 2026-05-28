package live.ditto.pos.core.domain.usecase

import live.ditto.pos.settings.AppSettings
import javax.inject.Inject

class UseDemoLocationUseCase @Inject constructor(private val repository: AppSettings) {

    suspend operator fun invoke(shouldUseDemoLocations: Boolean) {
        repository.shouldUseDemoLocations(useDemoLocations = shouldUseDemoLocations)
        repository.setLocationId(locationId = "")
    }
}
