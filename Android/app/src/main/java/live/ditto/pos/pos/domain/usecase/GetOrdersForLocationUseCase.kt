package live.ditto.pos.pos.domain.usecase

import kotlinx.coroutines.flow.Flow
import live.ditto.pos.core.data.Order
import live.ditto.pos.core.domain.repository.DittoRepository
import javax.inject.Inject

class GetOrdersForLocationUseCase @Inject constructor(
    private val dittoRepository: DittoRepository
) {

    operator fun invoke(): Flow<List<Order>> {
        return dittoRepository.ordersFlow()
    }
}
