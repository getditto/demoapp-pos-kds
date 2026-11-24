package live.ditto.pos.kds.presentation.composables

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import live.ditto.ui.AppButton
import live.ditto.ui.AppLayout
import live.ditto.ui.AppSurface
import live.ditto.ui.AppSurfaceStyle

@Composable
fun KitchenTicketCard(viewModel: live.ditto.pos.kds.KitchenTicketViewModel, onAdvance: () -> Unit, modifier: Modifier = Modifier) {
    AppSurface(modifier.fillMaxWidth(), style = AppSurfaceStyle.OUTLINED) {
        Column(verticalArrangement = Arrangement.spacedBy(AppLayout.gap)) {
            FlowRow(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalArrangement = Arrangement.spacedBy(AppLayout.smallGap)) {
                Text(viewModel.title, style = MaterialTheme.typography.titleLarge, modifier = Modifier.semantics { heading() })
                Text(viewModel.paymentTitle, style = MaterialTheme.typography.bodySmall, color = viewModel.paymentColor)
            }
            viewModel.lines.forEach { Text(it, style = MaterialTheme.typography.bodyLarge) }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                Text(viewModel.elapsed, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.weight(1f))
                Text(viewModel.stageTitle, style = MaterialTheme.typography.bodyMedium, color = viewModel.stageColor)
            }
            AppButton(viewModel.buttonTitle, onAdvance, Modifier.fillMaxWidth().semantics { contentDescription = viewModel.actionLabel }, secondary = viewModel.secondaryAction)
        }
    }
}
