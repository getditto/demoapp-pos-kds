package live.ditto.pos.pos.presentation.composables

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview

@Composable
fun CurrentOrderView() {
    Column(
        modifier = Modifier
            .fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(text = "Order: #39HFK2")
        HorizontalDivider()
        OrderItemsList()
        Spacer(modifier = Modifier.weight(1f))
        CheckoutSection()
    }
}

@Composable
@Preview
private fun CurrentOrderViewPreview() {
    CurrentOrderView()
}