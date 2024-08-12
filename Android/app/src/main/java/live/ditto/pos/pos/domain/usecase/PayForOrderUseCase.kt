package live.ditto.pos.pos.domain.usecase

import live.ditto.pos.core.data.Order
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.core.domain.repository.CoreRepository
import live.ditto.pos.core.domain.repository.DittoRepository
import javax.inject.Inject

class PayForOrderUseCase @Inject constructor(
    private val dittoRepository: DittoRepository,
    private val coreRepository: CoreRepository
) {

    suspend operator fun invoke(order: Order) {
        dittoRepository.updateOrderStatus(order, OrderStatus.PROCESSED)
        coreRepository.setCurrentOrderId("")
    }
}
