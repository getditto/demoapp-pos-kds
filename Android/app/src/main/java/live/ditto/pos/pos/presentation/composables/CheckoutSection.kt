package live.ditto.pos.pos.presentation.composables

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import live.ditto.pos.R
import live.ditto.ui.DittoButton

@Composable
fun CheckoutSection(orderTotal: String, isPayButtonEnabled: Boolean, onPayButtonClicked: () -> Unit, onCancelButtonClicked: () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text(stringResource(R.string.label_total))
            Text(orderTotal)
        }
        FlowRow(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            DittoButton("CLEAR", onCancelButtonClicked, enabled = isPayButtonEnabled, secondary = true)
            DittoButton(stringResource(R.string.button_pay).uppercase(), onPayButtonClicked, Modifier.weight(1f), enabled = isPayButtonEnabled)
        }
    }
}
