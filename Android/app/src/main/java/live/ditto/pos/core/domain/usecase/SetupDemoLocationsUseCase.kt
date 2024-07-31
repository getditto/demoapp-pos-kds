package live.ditto.pos.core.domain.usecase

import live.ditto.pos.core.domain.repository.CoreRepository
import live.ditto.pos.core.domain.repository.DittoRepository
import javax.inject.Inject

class SetupDemoLocationsUseCase @Inject constructor(
    private val coreRepository: CoreRepository,
    private val dittoRepository: DittoRepository
) {

    suspend operator fun invoke() {
        coreRepository.setLocationId(locationId = "")
        coreRepository.shouldUseDemoLocations(useDemoLocations = true)

        dittoRepository.insertDefaultLocations()
    }
}
