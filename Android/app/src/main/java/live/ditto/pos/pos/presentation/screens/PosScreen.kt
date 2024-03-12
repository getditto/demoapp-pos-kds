package live.ditto.pos.pos.presentation.screens

import androidx.compose.runtime.Composable
import live.ditto.pos.core.data.demoMenuData
import live.ditto.pos.pos.presentation.composables.SaleItemsGrid

@Composable
fun PosScreen() {
    SaleItemsGrid(saleItems = demoMenuData)
}