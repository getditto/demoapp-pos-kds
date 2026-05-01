package live.ditto.pos.pos.domain.usecase

import live.ditto.pos.core.data.orders.Order
import javax.inject.Inject

class CalculateOrderTotalUseCase @Inject constructor() {
    operator fun invoke(order: Order): Double = order.total.dollars
}
