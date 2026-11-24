package live.ditto.pos.inventory

import live.ditto.ui.AppCatalogRowViewModel
import live.ditto.ui.AppQuantityFieldViewModel
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class InventoryLayoutViewModelTest {
    @Test
    fun quantityControlsGrowAndReflowWithoutDisplacingOtherRowControls() {
        fun width(text: String, fontScale: Float = 1f) = AppQuantityFieldViewModel(text, fontScale).width.value
        assertEquals(width(""), width("0"))
        assertTrue(width("123456") > width("0"))
        assertTrue(width("123456", 2f) > width("123456"))
        assertEquals(width(Long.MAX_VALUE.toString()), width("9".repeat(100)))
        assertTrue(width("9".repeat(100), 3f) <= 144f)
        assertFalse(AppCatalogRowViewModel(345f, 1f).stacked)
        assertTrue(AppCatalogRowViewModel(280f, 1f).stacked)
        assertTrue(AppCatalogRowViewModel(345f, 1.5f).stacked)
        assertFalse(AppCatalogRowViewModel(1200f, 1.5f).stacked)
    }
}
