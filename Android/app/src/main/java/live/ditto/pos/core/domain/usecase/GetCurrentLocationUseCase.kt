package live.ditto.pos.core.domain.usecase

import live.ditto.pos.core.data.Location
import live.ditto.pos.core.data.demoLocations
import live.ditto.pos.core.domain.repository.CoreRepository
import javax.inject.Inject

class GetCurrentLocationUseCase @Inject constructor(private val coreRepository: CoreRepository) {

    // todo: this is currently finding a location that exists in the demoLocations hardcoded array
    // in the future this logic will change to consider whether demo locations or a custom location
    // is used ot not
    suspend operator fun invoke(): Location? {
        return demoLocations.find {
            it.id == coreRepository.locationId()
        }
    }
}
