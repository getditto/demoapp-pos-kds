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
import live.ditto.pos.R
import live.ditto.ui.AppButton
import live.ditto.ui.AppLayout
import live.ditto.ui.AppTextButton

@Composable
fun CheckoutSection(orderTotal: String, isPayButtonEnabled: Boolean, onPayButtonClicked: () -> Unit, onCancelButtonClicked: () -> Unit) {
    Column(Modifier.fillMaxWidth().padding(AppLayout.padding), verticalArrangement = Arrangement.spacedBy(AppLayout.mediumGap)) {
        FlowRow(Modifier.fillMaxWidth().heightIn(min = AppLayout.contentRowHeight), horizontalArrangement = Arrangement.spacedBy(AppLayout.gap)) {
            Text(stringResource(R.string.label_total))
            Text(orderTotal, Modifier.weight(1f), textAlign = TextAlign.End)
        }
        AppButton("${stringResource(R.string.button_pay).uppercase()} $orderTotal", onPayButtonClicked, Modifier.fillMaxWidth(), enabled = isPayButtonEnabled)
        AppTextButton("CLEAR CART", onCancelButtonClicked, Modifier.fillMaxWidth(), enabled = isPayButtonEnabled)
    }
}
