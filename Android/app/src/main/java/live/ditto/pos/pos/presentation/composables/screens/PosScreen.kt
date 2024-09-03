package live.ditto.pos.pos.presentation.composables.screens

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import live.ditto.pos.core.data.demoMenuData
import live.ditto.pos.pos.PoSViewModel
import live.ditto.pos.pos.presentation.composables.CurrentOrder
import live.ditto.pos.pos.presentation.composables.saleitemgrid.SaleItemsGrid

@Composable
fun PosScreen(
    viewModel: PoSViewModel = hiltViewModel()
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()

    Row(modifier = Modifier.fillMaxSize()) {
        Box(
            modifier = Modifier
                .fillMaxHeight()
                .fillMaxWidth(0.5f)
        ) {
            SaleItemsGrid(
                saleItems = demoMenuData,
                onSaleItemClicked = {
                    viewModel.addItemToCart(it)
                }
            )
        }
        Box(
            modifier = Modifier
                .fillMaxHeight()
        ) {
            CurrentOrder(
                orderId = state.currentOrderId,
                orderItems = state.orderItems,
                orderTotal = state.orderTotal,
                onPayButtonClicked = { viewModel.payForOrder() },
                onCancelButtonClicked = { viewModel.clearItems() }
            )
        }
    }
}

@Preview
@Composable
private fun PosScreenPreview() {
    PosScreen()
}
