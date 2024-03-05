package live.ditto.pos.pos.composables

import androidx.annotation.DrawableRes
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

@Composable
fun SaleItem(saleItemData: SaleItemData, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .wrapContentSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Image(
            painter = painterResource(id = saleItemData.imageResource),
            contentDescription = saleItemData.label
        )
        Text(text = saleItemData.label)
    }
}

data class SaleItemData(
    @DrawableRes val imageResource: Int,
    val label: String
)

@Preview(showBackground = true)
@Composable
fun SaleItemPreview() {
    SaleItem(saleItemData = saleItemPreviewData)
}

private val saleItemPreviewData = SaleItemData(
    imageResource = R.drawable.burger, label = "Tasty Burger"
)