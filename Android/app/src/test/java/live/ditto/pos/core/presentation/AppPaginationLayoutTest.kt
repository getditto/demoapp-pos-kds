package live.ditto.pos.core.presentation

import live.ditto.ui.AppPaginationLayout
import org.junit.Assert.assertEquals
import org.junit.Test

class AppPaginationLayoutTest {
    @Test
    fun paginationKeepsButtonsReachableInNarrowWindowsAndWithLargeText() {
        val windows = listOf(393f to 1f, 320f to 1f, 1200f to 1.5f, 393f to 1f)
        assertEquals(listOf(false, true, true, false), windows.map { (width, fontScale) -> AppPaginationLayout(width, fontScale).stacked })
    }
}
