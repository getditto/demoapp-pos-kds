package live.ditto.ui

import androidx.compose.ui.unit.dp

class AppQuantityFieldViewModel(text: String, fontScale: Float) {
    val width = (text.length * DIGIT_WIDTH_DP * fontScale + AppLayout.padding.value)
        .coerceIn(AppLayout.controlHeight.value, MAXIMUM_WIDTH_DP).dp

    private companion object {
        const val DIGIT_WIDTH_DP = 11f
        const val MAXIMUM_WIDTH_DP = 144f
    }
}

class AppCatalogRowViewModel(availableWidth: Float, fontScale: Float) {
    val stacked = availableWidth < MINIMUM_ROW_WIDTH_DP * fontScale

    private companion object {
        const val MINIMUM_ROW_WIDTH_DP = 320f
    }
}
