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
class GetCurrentOpenOrderUseCase @Inject constructor(
    private val dittoRepository: DittoRepository,
    private val generateOrderIdUseCase: GenerateOrderIdUseCase,
    private val currentLocationUseCase: GetCurrentLocationUseCase
) {

    suspend operator fun invoke(): Flow<Order> {
        val currentOrderId = generateOrderIdUseCase()
        return dittoRepository.ordersFlow()
            .map { orders ->
                getOrCreateNewOrder(orders, currentOrderId)
            }
    }

    private suspend fun getOrCreateNewOrder(orders: List<Order>, currentOrderId: String): Order {
        return orders.filter { it.status == OrderStatus.OPEN.ordinal }
            .findOrderById(currentOrderId) ?: generateNewOrder(currentOrderId)
    }

    // todo: move this logic to a use case?
    private suspend fun generateNewOrder(currentOrderId: String): Order {
        val currentLocationId = currentLocationUseCase()?.id ?: ""
        return Order(
            id = mapOf(
                "id" to currentOrderId,
                "locationId" to currentLocationId
            ),
            createdOn = "todo: create created on date generator",
            deviceId = "todo: create device id use case",
            saleItemIds = null,
            status = OrderStatus.OPEN.ordinal,
            transactionIds = emptyMap()
        )
    }
}
