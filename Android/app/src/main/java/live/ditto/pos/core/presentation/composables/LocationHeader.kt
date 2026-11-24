package live.ditto.pos.core.presentation.composables

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import live.ditto.ui.AppHeader
import live.ditto.ui.AppIcon
import live.ditto.ui.AppLayout
import live.ditto.ui.R

@Composable
fun LocationHeader(title: String, location: String, expanded: Boolean, modifier: Modifier = Modifier) {
    AppHeader(title, modifier, expanded) {
        if (location.isNotEmpty()) {
            Row(Modifier.weight(1f), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(AppLayout.accessoryGap, Alignment.End)) {
                AppIcon(R.drawable.phosphor_map_pin, size = AppLayout.secondaryIconSize)
                Text(location, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}
