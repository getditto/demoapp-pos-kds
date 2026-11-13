package live.ditto.pos.pos.presentation.composables

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.ditto.kotlin.DittoStore
import live.ditto.pos.core.presentation.images.OrderLinePhoto
import live.ditto.pos.pos.presentation.uimodel.OrderItemUiModel
import live.ditto.ui.DittoPhoto

@Composable
fun ColumnScope.OrderItemsList(
    orderItems: List<OrderItemUiModel>,
    photoStore: DittoStore? = null
) {
    val listState = rememberLazyListState()

    LaunchedEffect(orderItems.size) {
        listState.animateScrollToItem(orderItems.size)
    }

    LazyColumn(
        modifier = Modifier
            .fillMaxHeight()
            .weight(1f),
        state = listState
    ) {
        items(orderItems) { orderItem ->
            OrderItem(orderItem = orderItem, photoStore = photoStore)
            HorizontalDivider()
        }
    }
}

@Composable
fun OrderItem(orderItem: OrderItemUiModel, photoStore: DittoStore? = null) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (photoStore != null && orderItem.line != null && orderItem.orderId != null) {
            OrderLinePhoto(orderItem.line, orderItem.orderId, photoStore, Modifier.size(40.dp))
        } else {
            DittoPhoto(null, Modifier.size(40.dp))
        }
        Text(text = orderItem.name, modifier = Modifier.weight(1f))
        Text(text = orderItem.price)
    }
}

@Composable
@Preview
private fun OrderItemsListPreview() {
    Column {
        OrderItemsList(
            orderItems = listOf(
                OrderItemUiModel(name = "Burger", price = "$8.50"),
                OrderItemUiModel(name = "Fries", price = "$3.50"),
                OrderItemUiModel(name = "Coffee", price = "$1.95")
            )
        )
    }
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
