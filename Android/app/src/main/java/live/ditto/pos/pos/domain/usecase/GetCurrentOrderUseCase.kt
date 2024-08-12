package live.ditto.pos.pos.domain.usecase

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import live.ditto.pos.core.data.Order
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.core.data.findOrderById
import live.ditto.pos.core.domain.repository.DittoRepository
import live.ditto.pos.core.domain.usecase.GetCurrentLocationUseCase
import javax.inject.Inject

/**
 * Gets the current order id and use it to find an order that currently exists with that ID that
 * has the status of open. If that order is found, return it, otherwise this means we need to
 * create a new blank order
 */
class GetCurrentOrderUseCase @Inject constructor(
    private val dittoRepository: DittoRepository,
    private val generateOrderIdUseCase: GenerateOrderIdUseCase,
    private val createNewOrderUseCase: CreateNewOrderUseCase,
    private val currentLocationUseCase: GetCurrentLocationUseCase
) {

    suspend operator fun invoke(): Flow<Order> {
        val currentOrderId = generateOrderIdUseCase()
        val locationId = currentLocationUseCase()?.id ?: ""
        return dittoRepository.ordersForLocation(
            locationId = locationId
        )
            .map { orders ->
                getOrCreateNewOrder(orders, currentOrderId)
            }
    }

    private suspend fun getOrCreateNewOrder(orders: List<Order>, currentOrderId: String): Order {
        val order = orders.findOrderById(currentOrderId)?.takeIf {
            it.status == OrderStatus.OPEN.ordinal || it.status == OrderStatus.IN_PROCESS.ordinal
        }
        return order ?: createNewOrderUseCase()
    }
}
