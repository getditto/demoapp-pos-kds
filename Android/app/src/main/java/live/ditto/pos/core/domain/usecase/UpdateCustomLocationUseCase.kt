package live.ditto.pos.core.domain.usecase

import live.ditto.pos.core.data.locations.Location
import live.ditto.pos.core.domain.repository.CoreRepository
import live.ditto.pos.core.domain.repository.DittoRepository
import javax.inject.Inject

class UpdateCustomLocationUseCase @Inject constructor(
    private val coreRepository: CoreRepository,
    private val dittoRepository: DittoRepository,
    private val setCurrentLocationUseCase: SetCurrentLocationUseCase
) {

    suspend operator fun invoke(companyName: String, locationName: String) {
        val customLocation = Location(
            id = "$companyName-$locationName",
            name = locationName
        )
        dittoRepository.insertCustomLocation(customLocation = customLocation)
        coreRepository.shouldUseDemoLocations(useDemoLocations = false)
        setCurrentLocationUseCase(locationId = customLocation.id)
    }
}
