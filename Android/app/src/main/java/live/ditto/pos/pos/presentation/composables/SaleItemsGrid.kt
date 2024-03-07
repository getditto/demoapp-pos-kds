package live.ditto.pos.pos.presentation.composables

import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import live.ditto.pos.R

@Composable
fun SaleItemsGrid(saleItems: List<SaleItemData>) {
    LazyVerticalGrid(
        modifier = Modifier.padding(4.dp),
        columns = GridCells.Adaptive(minSize = 200.dp)
    ) {
        items(saleItems) { saleItem ->
            SaleItem(saleItemData = saleItem)
        }
    }
}

@Preview(showBackground = true)
@Composable
fun SaleItemsGridPreview() {
    SaleItemsGrid(saleItems = saleItemsPreviewData)
}

private val saleItemsPreviewData = mutableListOf<SaleItemData>().apply {
    repeat(10) {
        this.add(
            SaleItemData(imageResource = R.drawable.burrito, label = "Burrito #${it + 1}")
        )
    }
}