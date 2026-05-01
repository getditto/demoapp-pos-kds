package live.ditto.pos.pos.domain.usecase

import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.core.domain.repository.DittoRepository
import live.ditto.pos.core.domain.usecase.GetCurrentLocationUseCase
import javax.inject.Inject

class CreateNewOrderUseCase @Inject constructor(
    private val getCurrentLocationUseCase: GetCurrentLocationUseCase,
    private val dittoRepository: DittoRepository
) {

    suspend operator fun invoke(): Order {
        val locationId = getCurrentLocationUseCase()?.id ?: ""
        val order = Order.new(locationId = locationId)
        dittoRepository.upsertOrder(order)
        return order
    }
}
