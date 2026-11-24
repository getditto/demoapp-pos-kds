package live.ditto.ui

import androidx.compose.ui.unit.dp

class AppPaginationLayout(availableWidth: Float, fontScale: Float) {
    val stacked = availableWidth < MINIMUM_WIDTH || fontScale >= LARGE_FONT_SCALE

    companion object {
        private const val MINIMUM_WIDTH = 340f
        private const val LARGE_FONT_SCALE = 1.5f
        internal val buttonWidth = 120.dp
    }
}
