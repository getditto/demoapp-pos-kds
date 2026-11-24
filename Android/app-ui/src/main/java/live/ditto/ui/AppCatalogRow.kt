package live.ditto.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp

@Composable
fun AppCatalogRow(name: String, price: String, modifier: Modifier = Modifier, photo: @Composable () -> Unit, controls: @Composable () -> Unit) {
    Surface(modifier.fillMaxWidth(), shape = RoundedCornerShape(AppLayout.radius), color = MaterialTheme.colorScheme.surface) {
        BoxWithConstraints(Modifier.padding(horizontal = 8.dp, vertical = 12.dp)) {
            val stacked = maxWidth < 320.dp * LocalDensity.current.fontScale
            if (stacked) {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    CatalogDetails(name, price, photo)
                    Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.CenterEnd) { controls() }
                }
            } else {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Box(Modifier.weight(1f)) { CatalogDetails(name, price, photo) }
                    controls()
                }
            }
        }
    }
}

@Composable
private fun CatalogDetails(name: String, price: String, photo: @Composable () -> Unit) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Box(Modifier.size(40.dp)) { photo() }
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(name, style = MaterialTheme.typography.bodyLarge)
            Text(price, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
fun AppCounter(canDecrement: Boolean, decrement: () -> Unit, increment: () -> Unit, modifier: Modifier = Modifier, canIncrement: Boolean = true, value: @Composable () -> Unit) {
    Row(modifier, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(AppLayout.gap)) {
        IconButton(decrement, Modifier.size(AppLayout.controlHeight), enabled = canDecrement) {
            AppIcon(R.drawable.phosphor_minus, description = "Decrease quantity", size = 22.dp)
        }
        value()
        IconButton(increment, Modifier.size(AppLayout.controlHeight), enabled = canIncrement) {
            AppIcon(R.drawable.phosphor_plus, description = "Increase quantity", size = 22.dp)
        }
    }
}
