package live.ditto.pos.pos.presentation.composables

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import live.ditto.pos.R
import live.ditto.pos.pos.presentation.uimodel.OrderItemUiModel

@Composable
fun CurrentOrder(
    orderId: String,
    orderItems: List<OrderItemUiModel>,
    orderTotal: String,
    onPayButtonClicked: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(text = stringResource(R.string.current_order_id, orderId))
        HorizontalDivider()
        OrderItemsList(
            orderItems = orderItems
        )
        CheckoutSection(
            orderTotal = orderTotal,
            isPayButtonEnabled = orderItems.isNotEmpty(),
            onPayButtonClicked = onPayButtonClicked
        )
    }
}

@Composable
@Preview
private fun CurrentOrderViewPreview() {
    CurrentOrder(
        orderId = "#2311FFC",
        orderItems = emptyList(),
        orderTotal = "$13.37",
        onPayButtonClicked = { }
    )
}
