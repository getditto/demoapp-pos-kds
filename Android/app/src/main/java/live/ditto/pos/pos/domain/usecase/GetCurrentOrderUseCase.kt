package live.ditto.pos.pos.domain.usecase

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.domain.repository.CoreRepository
import live.ditto.pos.core.domain.repository.DittoRepository
import live.ditto.pos.core.domain.usecase.GetCurrentLocationUseCase
import javax.inject.Inject

/**
 * Returns a Flow of the order currently being built at the active location.
 * Reuses the saved `currentOrderId` if a matching open/in-process order exists;
 * otherwise creates a fresh order.
 */
class GetCurrentOrderUseCase @Inject constructor(
    private val coreRepository: CoreRepository,
    private val dittoRepository: DittoRepository,
    private val createNewOrderUseCase: CreateNewOrderUseCase,
    private val currentLocationUseCase: GetCurrentLocationUseCase
) {

    suspend operator fun invoke(): Flow<Order> {
        val locationId = currentLocationUseCase()?.id ?: ""
        val savedOrderId = coreRepository.currentOrderId()
        return dittoRepository.observeLocationOrders(locationId).map { orders ->
            val match = orders.firstOrNull { it.id == savedOrderId }?.takeIf {
                it.status == OrderStatus.OPEN || it.status == OrderStatus.IN_PROCESS
            }
            match ?: createNewOrderUseCase().also { coreRepository.setCurrentOrderId(it.id) }
        }
    }
}
