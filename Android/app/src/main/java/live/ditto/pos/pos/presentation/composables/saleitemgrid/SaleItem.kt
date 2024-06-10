package live.ditto.pos.pos.presentation.composables.saleitemgrid

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyGridItemScope
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import live.ditto.pos.R
import live.ditto.pos.pos.presentation.uimodel.SaleItemUiModel

@Composable
fun LazyGridItemScope.SaleItem(
    modifier: Modifier = Modifier,
    saleItemUiModel: SaleItemUiModel,
    onClick: () -> Unit
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
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Image(
                modifier = Modifier
                    .fillMaxSize()
                    .clip(RoundedCornerShape(8.dp)),
                painter = painterResource(id = saleItemUiModel.imageResource),
                contentDescription = saleItemUiModel.label
            )
        }
        Text(
            text = saleItemUiModel.label,
            textAlign = TextAlign.Center,
            style = MaterialTheme.typography.labelLarge,
            modifier = Modifier
                .padding(8.dp)
                .fillMaxWidth()
        )
    }
}

@Preview
@Composable
private fun SaleItemPreview() {
    val saleItems = listOf(
        SaleItemUiModel(
            imageResource = R.drawable.burger,
            label = "Tasty Burger"
        )
    )
    LazyVerticalGrid(columns = GridCells.Adaptive(120.dp)) {
        items(saleItems) { saleItem ->
            SaleItem(
                saleItemUiModel = saleItem,
                onClick = { }
            )
        }
    }
}
