package live.ditto.pos.pos.domain.usecase

import kotlinx.coroutines.flow.first
import live.ditto.pos.core.domain.repository.DittoRepository
import javax.inject.Inject

class ClearCurrentOrderSaleItemsUseCase @Inject constructor(
    private val dittoRepository: DittoRepository,
    private val getCurrentOrderUseCase: GetCurrentOrderUseCase
) {

    suspend operator fun invoke() {
        val order = getCurrentOrderUseCase().first()
        dittoRepository.clearSaleItemIds(order = order)
    }
}
