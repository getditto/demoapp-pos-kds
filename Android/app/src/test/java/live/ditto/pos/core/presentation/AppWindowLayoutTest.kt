package live.ditto.pos.core.presentation

import live.ditto.ui.AppWindowLayout
import org.junit.Assert.assertEquals
import org.junit.Test

class AppWindowLayoutTest {
    @Test
    fun availableWindowWidthsChooseCompactAndExpandedPresentation() {
        val availableWidths = listOf(393f, 1200f, 480f)
        val windows = availableWidths.map(::AppWindowLayout)
        assertEquals(listOf(false, true, false), windows.map { it.expanded })
    }
}
