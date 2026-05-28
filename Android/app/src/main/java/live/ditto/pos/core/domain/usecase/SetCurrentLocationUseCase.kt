package live.ditto.pos.core.domain.usecase

import live.ditto.pos.core.domain.repository.CoreRepository
import javax.inject.Inject

class SetCurrentLocationUseCase @Inject constructor(
    private val coreRepository: CoreRepository
) {

    // Persist the chosen locationId; DittoRepository observes the same flow
    // and registers the orders + sale_items subscriptions for the new value.
    suspend operator fun invoke(locationId: String) {
        coreRepository.setLocationId(locationId = locationId)
    }
}
