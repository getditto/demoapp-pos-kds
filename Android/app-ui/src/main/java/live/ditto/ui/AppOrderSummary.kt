package live.ditto.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp

enum class AppStatusTone { SECONDARY, ACTIVE, SUCCESS }

@Composable
fun AppOrderSummary(title: String, summary: String, status: String, tone: AppStatusTone, date: String, total: String, expanded: Boolean, modifier: Modifier = Modifier) {
    val statusColor = when (tone) {
        AppStatusTone.ACTIVE -> AppColors.brandText
        AppStatusTone.SUCCESS -> AppColors.success
        AppStatusTone.SECONDARY -> MaterialTheme.colorScheme.onSurfaceVariant
    }
    Surface(modifier.fillMaxWidth().semantics(mergeDescendants = true) {}, shape = RoundedCornerShape(12.dp), color = MaterialTheme.colorScheme.surface) {
        if (expanded && LocalDensity.current.fontScale < 1.5f) {
            Row(Modifier.padding(AppLayout.padding).heightIn(min = 40.dp), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                Text(title, Modifier.width(168.dp), style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
                Text(summary, Modifier.weight(1f), style = MaterialTheme.typography.bodyLarge)
                Text(status, Modifier.width(100.dp), style = MaterialTheme.typography.bodyMedium, color = statusColor)
                Text(date, Modifier.width(150.dp), style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text(total, Modifier.width(80.dp), style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
            }
        } else {
            Column(Modifier.padding(AppLayout.padding), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                FlowRow(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(title, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
                    Text(status, style = MaterialTheme.typography.bodyMedium, color = statusColor)
                }
                FlowRow(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(summary, style = MaterialTheme.typography.bodyLarge)
                    Text(total, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
                }
                Text(date, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

@Composable
fun AppPagination(label: String, canPrevious: Boolean, canNext: Boolean, previous: () -> Unit, next: () -> Unit, modifier: Modifier = Modifier) {
    BoxWithConstraints(modifier.fillMaxWidth()) {
        val stacked = maxWidth < 340.dp || LocalDensity.current.fontScale >= 1.5f
        if (stacked) {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(label, Modifier.fillMaxWidth(), style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Medium, textAlign = TextAlign.Center, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    AppButton("PREVIOUS", previous, enabled = canPrevious, secondary = true)
                    AppButton("NEXT", next, enabled = canNext, secondary = true)
                }
            }
        } else {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                AppButton("PREVIOUS", previous, Modifier.widthIn(min = 120.dp), enabled = canPrevious, secondary = true)
                Text(label, Modifier.weight(1f), style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Medium, textAlign = TextAlign.Center, color = MaterialTheme.colorScheme.onSurfaceVariant)
                AppButton("NEXT", next, Modifier.widthIn(min = 120.dp), enabled = canNext, secondary = true)
            }
        }
    }
}
