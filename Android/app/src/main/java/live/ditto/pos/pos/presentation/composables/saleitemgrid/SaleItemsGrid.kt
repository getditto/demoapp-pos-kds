package live.ditto.pos.pos.presentation.composables.saleitemgrid

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.runtime.Composable
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import live.ditto.pos.R
import live.ditto.pos.pos.data.SaleItemUiModel

@Composable
fun SaleItemsGrid(saleItems: List<SaleItemUiModel>) {
    LazyVerticalGrid(
        columns = GridCells.Adaptive(120.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        contentPadding = PaddingValues(8.dp),
    ) {
        items(saleItems) { saleItem ->
            SaleItem(saleItemUiModel = saleItem)
        }
    }

}

@Preview
@Composable
private fun SaleItemsGridPreview() {
    val saleItemsPreviewData = mutableListOf<SaleItemUiModel>().apply {
        repeat(10) {
            add(
                SaleItemUiModel(imageResource = R.drawable.burrito, label = "Burrito #${it + 1}")
            )
        }
    }
    SaleItemsGrid(saleItems = saleItemsPreviewData)
}