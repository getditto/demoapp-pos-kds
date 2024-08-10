package live.ditto.pos.pos.domain.usecase

import kotlinx.coroutines.flow.first
import live.ditto.pos.core.domain.repository.DittoRepository
import live.ditto.pos.pos.presentation.uimodel.SaleItemUiModel
import java.util.UUID
import javax.inject.Inject

class AddSaleItemToOrderUseCase @Inject constructor(
    private val getCurrentOrderUseCase: GetCurrentOrderUseCase,
    private val dittoRepository: DittoRepository
) {

    suspend operator fun invoke(saleItem: SaleItemUiModel) {
        val currentOrder = getCurrentOrderUseCase().first()

        // todo: use case to generate saleItemIdKey
        val saleItemIdKey = UUID.randomUUID().toString()

        dittoRepository.addItemToOrder(
            order = currentOrder,
            saleItemIdKey = saleItemIdKey,
            saleItemId = saleItem.id
        )
    }
}
