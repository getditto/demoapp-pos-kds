package live.ditto.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle

internal class AppEmptyStateViewModel(private val prominent: Boolean) {
    val spacing = AppLayout.mediumGap
    val iconSize = if (prominent) AppLayout.successIconSize else AppLayout.emptyIconSize
    val iconColor: Color
        @Composable get() = if (prominent) AppColors.success else MaterialTheme.colorScheme.onSurfaceVariant
    val titleStyle: TextStyle
        @Composable get() = if (prominent) MaterialTheme.typography.titleLarge else MaterialTheme.typography.titleMedium
    val messageStyle: TextStyle
        @Composable get() = if (prominent) MaterialTheme.typography.bodyLarge else MaterialTheme.typography.bodyMedium
}
