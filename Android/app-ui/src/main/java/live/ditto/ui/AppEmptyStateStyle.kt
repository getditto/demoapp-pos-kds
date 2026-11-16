package live.ditto.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle

enum class AppEmptyStateStyle { STANDARD, SUCCESS, LARGE }

internal val AppEmptyStateStyle.spacing get() = if (this == AppEmptyStateStyle.LARGE) AppLayout.padding else AppLayout.mediumGap
internal val AppEmptyStateStyle.iconSize get() = when (this) {
        AppEmptyStateStyle.LARGE -> AppLayout.largeEmptyIconSize
        AppEmptyStateStyle.SUCCESS -> AppLayout.successIconSize
        AppEmptyStateStyle.STANDARD -> AppLayout.emptyIconSize
    }
internal val AppEmptyStateStyle.iconColor: Color
        @Composable get() get() = when (this) {
            AppEmptyStateStyle.LARGE -> MaterialTheme.colorScheme.onSurface
            AppEmptyStateStyle.SUCCESS -> AppColors.success
            AppEmptyStateStyle.STANDARD -> MaterialTheme.colorScheme.onSurfaceVariant
        }
internal val AppEmptyStateStyle.titleStyle: TextStyle
        @Composable get() get() = if (this == AppEmptyStateStyle.STANDARD) MaterialTheme.typography.titleMedium else MaterialTheme.typography.titleLarge
internal val AppEmptyStateStyle.messageStyle: TextStyle
        @Composable get() get() = if (this == AppEmptyStateStyle.STANDARD) MaterialTheme.typography.bodyMedium else MaterialTheme.typography.bodyLarge
