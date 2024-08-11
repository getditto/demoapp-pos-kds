package live.ditto.pos.pos.domain.usecase

import live.ditto.pos.core.data.Order
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.core.domain.repository.DittoRepository
import live.ditto.pos.core.domain.usecase.GetCurrentLocationUseCase
import javax.inject.Inject

class CreateNewOrderUseCase @Inject constructor(
    private val getCurrentLocationUseCase: GetCurrentLocationUseCase,
    private val generateOrderIdUseCase: GenerateOrderIdUseCase,
    private val currentTimeStringUseCase: GetCurrentTimeStringUseCase,
    private val dittoRepository: DittoRepository
) {

    suspend operator fun invoke(): Order {
        val currentLocationId = getCurrentLocationUseCase()?.id ?: ""
        val currentOrderId = generateOrderIdUseCase()
        val order = Order(
            id = mapOf(
                "id" to currentOrderId,
                "locationId" to currentLocationId
            ),
            createdOn = currentTimeStringUseCase(),
            deviceId = dittoRepository.getDeviceId(), // todo
            saleItemIds = null,
            status = OrderStatus.OPEN.ordinal,
            transactionIds = emptyMap()
        )

        dittoRepository.insertNewOrder(order = order)

        return order
    }
}
