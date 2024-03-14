package live.ditto.pos.pos.presentation.composables

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import live.ditto.pos.R
import live.ditto.pos.pos.data.SaleItemUiModel

@Composable
fun SaleItem(saleItemUiModel: SaleItemUiModel, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .wrapContentSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Image(
            painter = painterResource(id = saleItemUiModel.imageResource),
            contentDescription = saleItemUiModel.label
        )
        Text(text = saleItemUiModel.label)
    }
}

@Preview(showBackground = true)
@Composable
private fun SaleItemPreview() {
    val saleItemPreviewData = SaleItemUiModel(
        imageResource = R.drawable.burger, label = "Tasty Burger"
    )
    SaleItem(saleItemUiModel = saleItemPreviewData)
}