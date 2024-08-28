package live.ditto.pos.kds.domain

import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.data.orders.OrderStatus
import live.ditto.pos.core.domain.repository.DittoRepository
import javax.inject.Inject

class UpdateKDSOrderStatus @Inject constructor(
    private val dittoRepository: DittoRepository
) {

    suspend operator fun invoke(order: Order) {
        if (order.status == OrderStatus.IN_PROCESS.ordinal) {
            dittoRepository.updateOrderStatus(
                order = order,
                orderStatus = OrderStatus.PROCESSED
            )
        } else if (order.status == OrderStatus.PROCESSED.ordinal) {
            dittoRepository.updateOrderStatus(
                order = order,
                orderStatus = OrderStatus.DELIVERED
            )
        }
    }
}
