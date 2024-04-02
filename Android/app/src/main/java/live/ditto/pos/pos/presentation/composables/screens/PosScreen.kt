package live.ditto.pos.pos.presentation.composables.screens

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import live.ditto.pos.core.data.demoMenuData
import live.ditto.pos.pos.presentation.composables.CurrentOrderView
import live.ditto.pos.pos.presentation.composables.saleitemgrid.SaleItemsGrid

@Composable
fun PosScreen() {
    Row(modifier = Modifier.fillMaxSize()) {
        Box(
            modifier = Modifier
                .fillMaxHeight()
                .fillMaxWidth(0.5f)
        ) {
            SaleItemsGrid(saleItems = demoMenuData)
        }
        Box(
            modifier = Modifier
                .fillMaxHeight()
        ) {
            CurrentOrderView()
        }
    }
}

@Preview
@Composable
private fun PosScreenPreview() {
    PosScreen()
}