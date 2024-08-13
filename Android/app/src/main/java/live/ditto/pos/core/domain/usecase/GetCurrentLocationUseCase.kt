package live.ditto.pos.core.domain.usecase

import live.ditto.pos.core.data.demoLocations
import live.ditto.pos.core.data.locations.Location
import live.ditto.pos.core.domain.repository.CoreRepository
import live.ditto.pos.core.domain.repository.DittoRepository
import javax.inject.Inject

class GetCurrentLocationUseCase @Inject constructor(
    private val coreRepository: CoreRepository,
    private val dittoRepository: DittoRepository
) {

    suspend operator fun invoke(): Location? {
        val locationId = coreRepository.locationId()
        if (locationId.isEmpty()) return null
        return if (coreRepository.isUsingDemoLocations()) {
            demoLocations.find {
                it.id == locationId
            }
        } else {
            dittoRepository.getLocationById(locationId = locationId)
        }
    }
}
