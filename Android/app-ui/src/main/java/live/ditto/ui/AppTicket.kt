package live.ditto.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics

@Composable
fun AppTicket(title: String, lines: List<String>, isPaid: Boolean, elapsed: String, isReady: Boolean, onAdvance: () -> Unit, modifier: Modifier = Modifier) {
    val viewModel = AppTicketViewModel(title, isPaid, isReady)
    Surface(modifier.fillMaxWidth(), shape = RoundedCornerShape(AppLayout.radius), color = MaterialTheme.colorScheme.surface, border = BorderStroke(AppLayout.borderWidth, AppColors.subtleBorder)) {
        Column(Modifier.padding(AppLayout.padding), verticalArrangement = Arrangement.spacedBy(AppLayout.gap)) {
            FlowRow(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalArrangement = Arrangement.spacedBy(AppLayout.smallGap)) {
                Text(title, style = MaterialTheme.typography.titleLarge, modifier = Modifier.semantics { heading() })
                Text(viewModel.paymentTitle, style = MaterialTheme.typography.bodySmall, color = viewModel.paymentColor)
            }
            lines.forEach { Text(it, style = MaterialTheme.typography.bodyLarge) }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                Text(elapsed, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.weight(1f))
                Text(viewModel.stageTitle, style = MaterialTheme.typography.bodyMedium, color = viewModel.stageColor)
            }
            AppButton(viewModel.buttonTitle, onAdvance, Modifier.fillMaxWidth().semantics { contentDescription = viewModel.actionLabel }, secondary = viewModel.secondaryAction)
        }
    }
}
