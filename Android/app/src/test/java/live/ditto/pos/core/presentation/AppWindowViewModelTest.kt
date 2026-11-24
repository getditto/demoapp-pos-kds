package live.ditto.pos.core.presentation

import live.ditto.ui.AppWindowViewModel
import org.junit.Assert.assertEquals
import org.junit.Test

class AppWindowViewModelTest {
    @Test
    fun availableWindowWidthsChooseCompactAndExpandedPresentation() {
        val availableWidths = listOf(393f, 1200f, 480f)
        val windows = availableWidths.map(::AppWindowViewModel)
        assertEquals(listOf(false, true, false), windows.map { it.expanded })
    }
}
