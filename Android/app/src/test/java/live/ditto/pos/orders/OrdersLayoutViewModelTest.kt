package live.ditto.pos.orders

import live.ditto.ui.AppOrderSummaryViewModel
import live.ditto.ui.AppPaginationViewModel
import org.junit.Assert.assertEquals
import org.junit.Test

class OrdersLayoutViewModelTest {
    @Test
    fun orderColumnsReflowForPhoneAndLargeTextThenReturnToWideLayout() {
        val widths = listOf(393f, 1200f, 1200f, 393f, 1200f)
        val fontScales = listOf(1f, 1f, 1.5f, 1.5f, 1f)
        val layouts = widths.zip(fontScales).map { (width, fontScale) ->
            AppOrderSummaryViewModel(AppOrderSummaryViewModel.supportsColumns(width), fontScale).usesColumns
        }
        assertEquals(listOf(false, true, false, false, true), layouts)
    }

    @Test
    fun paginationKeepsButtonsReachableInNarrowWindowsAndWithLargeText() {
        val windows = listOf(393f to 1f, 320f to 1f, 1200f to 1.5f, 393f to 1f)
        assertEquals(listOf(false, true, true, false), windows.map { (width, fontScale) -> AppPaginationViewModel(width, fontScale).stacked })
    }
}
