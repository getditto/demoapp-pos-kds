package live.ditto.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

class AppOrderSummaryViewModel(expanded: Boolean, fontScale: Float) {
    val usesColumns = expanded && fontScale < AppOrderLayout.LARGE_FONT_SCALE

    companion object {
        fun supportsColumns(availableWidth: Float) = availableWidth >= AppOrderLayout.MINIMUM_TABLE_WIDTH_DP
    }
}

internal object AppOrderLayout {
    const val LARGE_FONT_SCALE = 1.5f
    const val MINIMUM_TABLE_WIDTH_DP = 760f
    const val MINIMUM_PAGINATION_WIDTH_DP = 340f
    val titleWidth = 168.dp
    val statusWidth = 100.dp
    val dateWidth = 150.dp
    val totalWidth = 80.dp
    val paginationButtonWidth = 120.dp
}

class AppPaginationViewModel(availableWidth: Float, fontScale: Float) {
    val stacked = availableWidth < AppOrderLayout.MINIMUM_PAGINATION_WIDTH_DP || fontScale >= AppOrderLayout.LARGE_FONT_SCALE
}

internal val AppStatusTone.color: Color
    @Composable get() = when (this) {
        AppStatusTone.ACTIVE -> AppColors.brandText
        AppStatusTone.SUCCESS -> AppColors.success
        AppStatusTone.SECONDARY -> MaterialTheme.colorScheme.onSurfaceVariant
    }
