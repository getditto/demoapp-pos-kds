package live.ditto.pos.orders

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import live.ditto.ui.AppLayout
import live.ditto.ui.AppSurface
import live.ditto.ui.AppSurfaceStyle

@Composable
internal fun OrderSummaryRow(viewModel: OrderSummaryViewModel, modifier: Modifier = Modifier) {
    AppSurface(modifier.fillMaxWidth().semantics(mergeDescendants = true) {}, style = AppSurfaceStyle.COMPACT) {
        if (viewModel.usesColumns) {
            Row(Modifier.heightIn(min = AppLayout.contentRowHeight), horizontalArrangement = Arrangement.spacedBy(AppLayout.gap), verticalAlignment = Alignment.CenterVertically) {
                Text(viewModel.title, Modifier.width(OrderSummaryLayout.titleWidth), style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
                Text(viewModel.summary, Modifier.weight(1f), style = MaterialTheme.typography.bodyLarge)
                Text(viewModel.status, Modifier.width(OrderSummaryLayout.statusWidth), style = MaterialTheme.typography.bodyMedium, color = viewModel.statusColor)
                Text(viewModel.date, Modifier.width(OrderSummaryLayout.dateWidth), style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text(viewModel.total, Modifier.width(OrderSummaryLayout.totalWidth), style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
            }
        } else {
            Column(verticalArrangement = Arrangement.spacedBy(AppLayout.gap)) {
                FlowRow(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalArrangement = Arrangement.spacedBy(AppLayout.gap)) {
                    Text(viewModel.title, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
                    Text(viewModel.status, style = MaterialTheme.typography.bodyMedium, color = viewModel.statusColor)
                }
                FlowRow(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalArrangement = Arrangement.spacedBy(AppLayout.gap)) {
                    Text(viewModel.summary, style = MaterialTheme.typography.bodyLarge)
                    Text(viewModel.total, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
                }
                Text(viewModel.date, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}
