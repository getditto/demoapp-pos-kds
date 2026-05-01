package live.ditto.pos.kds.domain

import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.domain.repository.CoreRepository
import live.ditto.pos.core.domain.repository.DittoRepository
import javax.inject.Inject

class UpdateKDSOrderStatus @Inject constructor(
    private val dittoRepository: DittoRepository,
    private val coreRepository: CoreRepository
) {

    suspend operator fun invoke(order: Order) {
        val nextStatus = when (order.status) {
            OrderStatus.IN_PROCESS -> OrderStatus.PROCESSED
            OrderStatus.PROCESSED -> OrderStatus.DELIVERED
            else -> return
        }
        val updated = order.appendingStatus(nextStatus)
        dittoRepository.upsertOrder(updated)

        if (nextStatus == OrderStatus.PROCESSED && coreRepository.currentOrderId() == order.id) {
            coreRepository.setCurrentOrderId("")
        }
    }
}
