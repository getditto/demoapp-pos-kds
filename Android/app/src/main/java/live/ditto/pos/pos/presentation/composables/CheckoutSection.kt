package live.ditto.pos.pos.presentation.composables

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import live.ditto.pos.R
import live.ditto.ui.DittoButton
import live.ditto.ui.DittoLayout
import live.ditto.ui.DittoTextButton

@Composable
fun CheckoutSection(orderTotal: String, isPayButtonEnabled: Boolean, onPayButtonClicked: () -> Unit, onCancelButtonClicked: () -> Unit) {
    Column(Modifier.fillMaxWidth().padding(DittoLayout.padding), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        FlowRow(Modifier.fillMaxWidth().heightIn(min = 40.dp), horizontalArrangement = Arrangement.spacedBy(DittoLayout.gap)) {
            Text(stringResource(R.string.label_total))
            Text(orderTotal, Modifier.weight(1f), textAlign = TextAlign.End)
        }
        DittoButton("${stringResource(R.string.button_pay).uppercase()} $orderTotal", onPayButtonClicked, Modifier.fillMaxWidth(), enabled = isPayButtonEnabled)
        DittoTextButton("CLEAR CART", onCancelButtonClicked, Modifier.fillMaxWidth(), enabled = isPayButtonEnabled)
    }
}
