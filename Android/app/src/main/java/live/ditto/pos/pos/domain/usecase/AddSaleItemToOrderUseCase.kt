package live.ditto.pos.pos.domain.usecase

import kotlinx.coroutines.flow.first
import live.ditto.pos.core.domain.repository.DittoRepository
import java.util.UUID
import javax.inject.Inject

class AddSaleItemToOrderUseCase @Inject constructor(
    private val getCurrentOrderUseCase: GetCurrentOrderUseCase,
    private val currentTimeStringUseCase: GetCurrentTimeStringUseCase,
    private val dittoRepository: DittoRepository
) {

    companion object {
        /**
         * Format should be randomUUID_currentISO8601Time
         */
        const val SALE_ITEM_ID_FORMAT = "%s_%s"
    }

    suspend operator fun invoke(saleItemId: String) {
        val currentOrder = getCurrentOrderUseCase().first()

        val saleItemIdKey = generateSaleItemIdKey()

        dittoRepository.addItemToOrder(
            order = currentOrder,
            saleItemIdKey = saleItemIdKey,
            saleItemId = saleItemId
        )
    }

    private fun generateSaleItemIdKey(): String {
        val randomUUID = UUID.randomUUID().toString()
        val currentDateTime = currentTimeStringUseCase()
        return SALE_ITEM_ID_FORMAT.format(randomUUID, currentDateTime)
    }
}
