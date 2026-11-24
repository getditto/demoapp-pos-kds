package live.ditto.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle

enum class AppEmptyStateStyle { STANDARD, SUCCESS }

internal val AppEmptyStateStyle.spacing get() = AppLayout.mediumGap
internal val AppEmptyStateStyle.iconSize get() = if (this == AppEmptyStateStyle.SUCCESS) AppLayout.successIconSize else AppLayout.emptyIconSize
internal val AppEmptyStateStyle.iconColor: Color
    @Composable get() = if (this == AppEmptyStateStyle.SUCCESS) AppColors.success else MaterialTheme.colorScheme.onSurfaceVariant
internal val AppEmptyStateStyle.titleStyle: TextStyle
    @Composable get() = if (this == AppEmptyStateStyle.SUCCESS) MaterialTheme.typography.titleLarge else MaterialTheme.typography.titleMedium
internal val AppEmptyStateStyle.messageStyle: TextStyle
    @Composable get() = if (this == AppEmptyStateStyle.SUCCESS) MaterialTheme.typography.bodyLarge else MaterialTheme.typography.bodyMedium
