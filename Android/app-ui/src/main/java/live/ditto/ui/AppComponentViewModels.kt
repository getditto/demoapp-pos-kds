package live.ditto.ui

import androidx.compose.ui.unit.dp

class AppWindowViewModel(val expanded: Boolean) {
    constructor(width: Float) : this(width >= AppLayout.EXPANDED_BREAKPOINT_DP)

    val horizontalPadding = if (expanded) AppLayout.expandedPadding else AppLayout.padding
    val sectionSpacing = if (expanded) AppLayout.padding else AppLayout.mediumGap
}

internal class AppHeaderViewModel(val expanded: Boolean) {
    val horizontalPadding = AppWindowViewModel(expanded).horizontalPadding
    val verticalPadding = if (expanded) AppLayout.padding else 0.dp
    val height = if (expanded) AppLayout.expandedHeaderHeight else AppLayout.controlHeight
    val symbolWidth = if (expanded) AppLayout.expandedSymbolWidth else AppLayout.compactSymbolWidth
    val symbolHeight = if (expanded) AppLayout.expandedSymbolHeight else AppLayout.compactSymbolHeight
}

internal class AppRowViewModel(eyebrow: String?) {
    val minimumHeight = if (eyebrow != null) AppLayout.controlHeight else AppLayout.compactRowHeight
}
