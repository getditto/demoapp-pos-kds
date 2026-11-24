package live.ditto.pos.inventory

import live.ditto.pos.core.data.DocumentID
import live.ditto.pos.core.data.Price
import live.ditto.pos.core.data.SaleItem
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class InventoryRowViewModelTest {
    @Test
    fun quantityControlsGrowAndReflowWithoutDisplacingOtherRowControls() {
        val item = SaleItem(DocumentID("coffee", "A"), "Coffee", Price(195), 2)
        fun row(text: String = "0", fontScale: Float = 1f) = InventoryRowViewModel(item, QuantityEdit(item.documentId, text), fontScale)
        fun width(text: String, fontScale: Float = 1f) = row(text, fontScale).quantityWidth.value
        assertEquals(width(""), width("0"))
        assertTrue(width("123456") > width("0"))
        assertTrue(width("123456", 2f) > width("123456"))
        assertEquals(width(Long.MAX_VALUE.toString()), width("9".repeat(100)))
        assertTrue(width("9".repeat(100), 3f) <= 144f)
        assertFalse(row(fontScale = 1f).stacksControls(345f))
        assertTrue(row(fontScale = 1f).stacksControls(280f))
        assertTrue(row(fontScale = 1.5f).stacksControls(345f))
        assertFalse(row(fontScale = 1.5f).stacksControls(1200f))
    }
}
