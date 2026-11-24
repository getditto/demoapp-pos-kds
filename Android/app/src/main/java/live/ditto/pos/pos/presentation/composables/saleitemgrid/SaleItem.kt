package live.ditto.pos.pos.presentation.composables.saleitemgrid

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyGridItemScope
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import com.ditto.kotlin.DittoStore
import live.ditto.pos.core.data.DocumentID
import live.ditto.pos.core.presentation.images.ProductPhoto
import live.ditto.pos.pos.presentation.uimodel.SaleItemUiModel
import live.ditto.ui.AppLayout
import live.ditto.ui.AppPhoto

@Composable
fun LazyGridItemScope.SaleItem(
    modifier: Modifier = Modifier,
    saleItemUiModel: SaleItemUiModel,
    onClick: () -> Unit,
    photoStore: DittoStore? = null
) {
    Card(
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer
        ),
        modifier = modifier
            .fillMaxHeight(),
        onClick = onClick
    ) {
        Box(
            modifier = Modifier.fillMaxWidth().aspectRatio(1f),
            contentAlignment = Alignment.Center
        ) {
            if (photoStore != null) {
                ProductPhoto(saleItemUiModel.image, DocumentID(saleItemUiModel.id, saleItemUiModel.locationId), photoStore, Modifier.fillMaxSize())
            } else {
                AppPhoto(null, Modifier.fillMaxSize())
            }
        }
        Text(
            text = saleItemUiModel.label,
            textAlign = TextAlign.Center,
            style = MaterialTheme.typography.labelLarge,
            modifier = Modifier
                .padding(AppLayout.gap)
                .fillMaxWidth()
        )
    }
}

@Preview
@Composable
private fun SaleItemPreview() {
    val saleItems = listOf(
        SaleItemUiModel(
            id = "007",
            label = "Tasty Burger"
        )
    )
    LazyVerticalGrid(columns = GridCells.Adaptive(SaleItemsGridLayout.minimumItemWidth)) {
        items(saleItems) { saleItem ->
            SaleItem(
                saleItemUiModel = saleItem,
                onClick = { }
            )
        }
    }
}
