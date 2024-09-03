package live.ditto.pos.kds.domain

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.data.orders.OrderStatus
import live.ditto.pos.core.domain.repository.CoreRepository
import live.ditto.pos.core.domain.repository.DittoRepository
import javax.inject.Inject

class GetOrdersForKdsUseCase @Inject constructor(
    private val dittoRepository: DittoRepository,
    private val coreRepository: CoreRepository
) {

    suspend operator fun invoke(): Flow<List<Order>> {
        val locationId = coreRepository.locationId()
        return dittoRepository.ordersForLocation(locationId)
            .map { orders ->
                orders.filter { order ->
                    order.hasCorrectOrderStatus() && order.hasItems()
                }
            }
    }

    private fun Order.hasItems(): Boolean {
        return this.saleItemIds?.isNotEmpty() ?: false
    }

    private fun Order.hasCorrectOrderStatus(): Boolean {
        return this.status == OrderStatus.IN_PROCESS.ordinal ||
            this.status == OrderStatus.PROCESSED.ordinal
    }
}
