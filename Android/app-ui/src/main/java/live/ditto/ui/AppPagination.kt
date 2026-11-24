package live.ditto.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign

@Composable
fun AppPagination(label: String, canPrevious: Boolean, canNext: Boolean, previous: () -> Unit, next: () -> Unit, modifier: Modifier = Modifier) {
    BoxWithConstraints(modifier.fillMaxWidth()) {
        val layout = AppPaginationLayout(maxWidth.value, LocalDensity.current.fontScale)
        if (layout.stacked) {
            Column(verticalArrangement = Arrangement.spacedBy(AppLayout.mediumGap)) {
                Text(label, Modifier.fillMaxWidth(), style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Medium, textAlign = TextAlign.Center, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    AppButton("PREVIOUS", previous, enabled = canPrevious, secondary = true)
                    AppButton("NEXT", next, enabled = canNext, secondary = true)
                }
            }
        } else {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(AppLayout.mediumGap)) {
                AppButton("PREVIOUS", previous, Modifier.widthIn(min = AppPaginationLayout.buttonWidth), enabled = canPrevious, secondary = true)
                Text(label, Modifier.weight(1f), style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Medium, textAlign = TextAlign.Center, color = MaterialTheme.colorScheme.onSurfaceVariant)
                AppButton("NEXT", next, Modifier.widthIn(min = AppPaginationLayout.buttonWidth), enabled = canNext, secondary = true)
            }
        }
    }
}
