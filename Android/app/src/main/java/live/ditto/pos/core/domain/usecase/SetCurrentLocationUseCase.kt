package live.ditto.pos.core.domain.usecase

import live.ditto.pos.core.domain.repository.CoreRepository
import live.ditto.pos.core.domain.repository.DittoRepository
import javax.inject.Inject

class SetCurrentLocationUseCase @Inject constructor(
    private val coreRepository: CoreRepository,
    private val dittoRepository: DittoRepository
) {

    private val locationsSubscriptionQuery = """
        SELECT * FROM COLLECTION locations (saleItemIds MAP)
    """.trimIndent()

    suspend operator fun invoke(locationId: String) {
        coreRepository.setLocationId(locationId = locationId)
        dittoRepository.subscribe(query = locationsSubscriptionQuery)
    }
}
