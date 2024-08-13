package live.ditto.pos.pos.domain.usecase

import kotlinx.coroutines.flow.first
import live.ditto.pos.core.data.transactions.Transaction
import live.ditto.pos.core.data.transactions.TransactionStatus
import live.ditto.pos.core.data.transactions.TransactionType
import live.ditto.pos.core.domain.repository.CoreRepository
import live.ditto.pos.core.domain.repository.DittoRepository
import live.ditto.pos.core.domain.usecase.GetCurrentLocationUseCase
import java.util.UUID
import javax.inject.Inject

class PayForOrderUseCase @Inject constructor(
    private val dittoRepository: DittoRepository,
    private val coreRepository: CoreRepository,
    private val getCurrentLocationUseCase: GetCurrentLocationUseCase,
    private val getCurrentTimeStringUseCase: GetCurrentTimeStringUseCase,
    private val createNewOrderUseCase: CreateNewOrderUseCase,
    private val getCurrentOrderUseCase: GetCurrentOrderUseCase,
    private val calculateOrderTotalUseCase: CalculateOrderTotalUseCase
) {

    suspend operator fun invoke() {
        val currentOrder = getCurrentOrderUseCase().first()
        val locationId = getCurrentLocationUseCase()?.id ?: ""
        val orderTotal = calculateOrderTotalUseCase(order = currentOrder)

        val transaction = Transaction(
            id = mapOf(
                "id" to UUID.randomUUID().toString(),
                "locationId" to locationId,
                "orderId" to currentOrder.getOrderId()
            ),
            createdOn = getCurrentTimeStringUseCase(),
            type = TransactionType.CASH.ordinal,
            status = TransactionStatus.COMPLETE.ordinal,
            amount = orderTotal
        )
        dittoRepository.addTransaction(
            transaction = transaction,
            order = currentOrder
        )

        coreRepository.setCurrentOrderId("")
        createNewOrderUseCase()
    }
}
