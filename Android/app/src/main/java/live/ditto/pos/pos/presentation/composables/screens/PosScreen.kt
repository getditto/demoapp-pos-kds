package live.ditto.pos.pos.presentation.composables.screens

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import live.ditto.pos.pos.POSViewModel
import live.ditto.pos.pos.presentation.composables.CurrentOrder
import live.ditto.pos.pos.presentation.composables.saleitemgrid.SaleItemsGrid

@Composable
fun PosScreen(
    viewModel: POSViewModel = hiltViewModel()
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle(minActiveState = Lifecycle.State.RESUMED)

    if (state.isLoading) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
        return
    }

    Row(modifier = Modifier.fillMaxSize()) {
        Box(
            modifier = Modifier
                .fillMaxHeight()
                .fillMaxWidth(0.5f)
        ) {
            SaleItemsGrid(
                saleItems = state.saleItems,
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
                orderTitle = state.currentOrderTitle,
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
