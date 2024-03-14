package live.ditto.pos.pos.presentation.composables

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import live.ditto.pos.core.data.demoOrderItems
import live.ditto.pos.pos.data.OrderItemUiModel

@Composable
fun OrderItemsList() {
    LazyColumn {
        items(demoOrderItems) { orderItem ->
            OrderItem(orderItem = orderItem)
            HorizontalDivider()
        }
    }
}

@Composable
fun OrderItem(orderItem: OrderItemUiModel) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(text = orderItem.name)
        Text(text = orderItem.price)
    }
}

@Composable
@Preview
private fun OrderItemsListPreview() {
    OrderItemsList()
}

@Composable
@Preview
private fun OrderItemPreview() {
    val orderItemUiModel = OrderItemUiModel(
        name = "Tasty Taco",
        price = "$29.99"
    )
    OrderItem(orderItem = orderItemUiModel)
}