package live.ditto.pos.ui.theme

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import org.junit.Assert.assertTrue
import org.junit.Test

class PayButtonColorsTest {
    // WCAG 2.1 contrast ratio between two opaque colors.
    private fun contrast(a: Color, b: Color): Double {
        val (light, dark) = listOf(a.luminance(), b.luminance()).sortedDescending()
        return (light + 0.05) / (dark + 0.05)
    }

    @Test
    fun payButtonLabelMeetsNormalTextContrast() {
        val ratio = contrast(PayButtonContainerColor, PayButtonContentColor)
        assertTrue("Pay button contrast is $ratio, expected at least 4.5", ratio >= 4.5)
    }
}
