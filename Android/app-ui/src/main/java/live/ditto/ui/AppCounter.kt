package live.ditto.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.material3.IconButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier

@Composable
fun AppCounter(canDecrement: Boolean, decrement: () -> Unit, increment: () -> Unit, modifier: Modifier = Modifier, canIncrement: Boolean = true, value: @Composable () -> Unit) {
    Row(modifier, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(AppLayout.gap)) {
        IconButton(decrement, Modifier.size(AppLayout.controlHeight), enabled = canDecrement) {
            AppIcon(R.drawable.phosphor_minus, description = "Decrease quantity", size = AppLayout.actionIconSize)
        }
        value()
        IconButton(increment, Modifier.size(AppLayout.controlHeight), enabled = canIncrement) {
            AppIcon(R.drawable.phosphor_plus, description = "Increase quantity", size = AppLayout.actionIconSize)
        }
    }
}
