package live.ditto.pos.core.domain.usecase

import live.ditto.pos.core.data.Location
import live.ditto.pos.core.data.demoLocations
import live.ditto.pos.core.domain.repository.CoreRepository
import javax.inject.Inject

class GetCurrentLocationUseCase @Inject constructor(private val coreRepository: CoreRepository) {

    suspend operator fun invoke(): Location? {
        return demoLocations.find {
            it.id == coreRepository.locationId()
        }
    }
}
