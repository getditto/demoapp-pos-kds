package live.ditto.pos.pos.domain.usecase

import live.ditto.pos.core.data.demoMenuData
import live.ditto.pos.core.data.orders.Order
import live.ditto.pos.pos.presentation.uimodel.SaleItemUiModel
import javax.inject.Inject

class CalculateOrderTotalUseCase @Inject constructor() {

    operator fun invoke(order: Order): Double {
        var total = 0.0
        val saleItems = getSaleItemsFromOrder(saleItemIds = order.sortedSaleItemIds())
        saleItems.forEach {
            total += it.price
        }
        return total
    }

    private fun getSaleItemsFromOrder(saleItemIds: Collection<String>?): List<SaleItemUiModel> {
        val saleItems = saleItemIds?.mapNotNull { saleItemId ->
            demoMenuData.find { it.id == saleItemId }
        }
        return saleItems ?: emptyList()
    }
}
