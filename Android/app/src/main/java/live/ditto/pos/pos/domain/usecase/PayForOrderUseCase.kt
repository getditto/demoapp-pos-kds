package live.ditto.pos.pos.domain.usecase

import kotlinx.coroutines.flow.first
import live.ditto.pos.core.data.Payment
import live.ditto.pos.core.data.PaymentType
import live.ditto.pos.core.domain.repository.CoreRepository
import live.ditto.pos.core.domain.repository.DittoRepository
import javax.inject.Inject

class PayForOrderUseCase @Inject constructor(
    private val dittoRepository: DittoRepository,
    private val coreRepository: CoreRepository,
    private val createNewOrderUseCase: CreateNewOrderUseCase,
    private val getCurrentOrderUseCase: GetCurrentOrderUseCase
) {

    suspend operator fun invoke() {
        val currentOrder = getCurrentOrderUseCase().first()
        val payment = Payment(
            type = PaymentType.CASH,
            amount = currentOrder.total
        )
        val updated = currentOrder.addingPayment(payment, paymentId = Payment.newPaymentId())
        dittoRepository.upsertOrder(updated)

        coreRepository.setCurrentOrderId("")
        createNewOrderUseCase()
    }
}
