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
import androidx.compose.ui.unit.dp

@Composable
fun DittoTicket(title: String, lines: List<String>, isPaid: Boolean, elapsed: String, isReady: Boolean, onAdvance: () -> Unit, modifier: Modifier = Modifier) {
    Surface(modifier.fillMaxWidth(), shape = RoundedCornerShape(DittoLayout.radius), color = MaterialTheme.colorScheme.surface, border = BorderStroke(1.dp, DittoColors.subtleBorder)) {
        Column(Modifier.padding(DittoLayout.padding), verticalArrangement = Arrangement.spacedBy(DittoLayout.gap)) {
            FlowRow(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(title, style = MaterialTheme.typography.titleLarge, modifier = Modifier.semantics { heading() })
                Text(if (isPaid) "Paid" else "Unpaid", style = MaterialTheme.typography.bodySmall, color = if (isPaid) DittoColors.success else MaterialTheme.colorScheme.onSurfaceVariant)
            }
            lines.forEach { Text(it, style = MaterialTheme.typography.bodyLarge) }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                Text(elapsed, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.weight(1f))
                Text(if (isReady) "Ready" else "Preparing", style = MaterialTheme.typography.bodyMedium, color = if (isReady) DittoColors.success else DittoColors.brandText)
            }
            val action = if (isReady) "Complete order" else "Mark ready"
            DittoButton(action.uppercase(), onAdvance, Modifier.fillMaxWidth().semantics { contentDescription = "$action, $title" }, secondary = isReady)
        }
    }
}
