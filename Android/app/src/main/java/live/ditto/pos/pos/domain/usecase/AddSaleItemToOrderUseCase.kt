package live.ditto.pos.pos.domain.usecase

import kotlinx.coroutines.flow.first
import live.ditto.pos.core.data.CartLineItem
import live.ditto.pos.core.domain.repository.DittoRepository
import live.ditto.pos.core.domain.usecase.GetCurrentLocationUseCase
import javax.inject.Inject

class AddSaleItemToOrderUseCase @Inject constructor(
    private val getCurrentOrderUseCase: GetCurrentOrderUseCase,
    private val getCurrentLocationUseCase: GetCurrentLocationUseCase,
    private val dittoRepository: DittoRepository
) {

    suspend operator fun invoke(saleItemId: String) {
        val currentOrder = getCurrentOrderUseCase().first()
        val locationId = getCurrentLocationUseCase()?.id ?: return

        val saleItem = dittoRepository.observeLocationSaleItems(locationId).first()
            .firstOrNull { it.id == saleItemId } ?: return

        val lineItem = CartLineItem.from(saleItem)
        val updated = currentOrder.addingCartLineItem(lineItem, lineItemId = CartLineItem.newLineItemId())
        dittoRepository.upsertOrder(updated)
    }
}
