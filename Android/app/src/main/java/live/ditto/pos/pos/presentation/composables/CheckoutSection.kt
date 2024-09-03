package live.ditto.pos.pos.presentation.composables

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import live.ditto.pos.R

@Composable
fun CheckoutSection(
    orderTotal: String,
    isPayButtonEnabled: Boolean,
    onPayButtonClicked: () -> Unit,
    onCancelButtonClicked: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(text = stringResource(R.string.label_total))
            Text(text = orderTotal)
        }
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            CancelButton(
                enabled = isPayButtonEnabled,
                onCancelButtonClicked = onCancelButtonClicked
            )
            Button(
                enabled = isPayButtonEnabled,
                onClick = { onPayButtonClicked() },
                shape = RoundedCornerShape(4.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color.Green),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(text = stringResource(R.string.button_pay))
            }
        }
    }
}

@Composable
private fun CancelButton(
    enabled: Boolean,
    onCancelButtonClicked: () -> Unit
) {
    val colorFilter = if (enabled) {
        ColorFilter.tint(Color.Red)
    } else {
        ColorFilter.tint(Color.LightGray)
    }
    IconButton(
        enabled = enabled,
        onClick = { onCancelButtonClicked() }
    ) {
        Image(
            imageVector = Icons.Filled.Cancel,
            contentDescription = stringResource(R.string.button_cancel_order),
            colorFilter = colorFilter,
            modifier = Modifier
                .width(48.dp)
                .height(48.dp)
        )
    }
}

@Preview
@Composable
private fun CheckoutSectionPreview() {
    CheckoutSection(
        orderTotal = "$13.37",
        isPayButtonEnabled = true,
        onPayButtonClicked = {},
        onCancelButtonClicked = {}
    )
}
