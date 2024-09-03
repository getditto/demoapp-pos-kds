package live.ditto.pos.kds.domain

import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.data.orders.OrderStatus
import live.ditto.pos.core.domain.repository.CoreRepository
import live.ditto.pos.core.domain.repository.DittoRepository
import javax.inject.Inject

class UpdateKDSOrderStatus @Inject constructor(
    private val dittoRepository: DittoRepository,
    private val coreRepository: CoreRepository
) {

    suspend operator fun invoke(order: Order) {
        if (order.status == OrderStatus.IN_PROCESS.ordinal) {
            dittoRepository.updateOrderStatus(
                order = order,
                orderStatus = OrderStatus.PROCESSED
            )
            // If we're updating the current order id we need to make sure we reset the current
            // order id so the PoS display shows a new order, otherwise it will remain on the PoS
            // display and you'll be able to add orders to it
            val currentOrderId = coreRepository.currentOrderId()
            if (currentOrderId == order.getOrderId()) {
                coreRepository.setCurrentOrderId(orderId = "")
            }
        } else if (order.status == OrderStatus.PROCESSED.ordinal) {
            dittoRepository.updateOrderStatus(
                order = order,
                orderStatus = OrderStatus.DELIVERED
            )
        }
    }
}
