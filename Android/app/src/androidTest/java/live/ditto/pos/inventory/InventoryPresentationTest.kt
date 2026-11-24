package live.ditto.pos.inventory

import androidx.compose.foundation.background
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.unit.Density
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import live.ditto.pos.core.data.DocumentID
import live.ditto.pos.core.data.Price
import live.ditto.pos.core.data.SaleItem
import live.ditto.ui.BrandTheme
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

class InventoryPresentationTest {
    @get:Rule val compose = createComposeRule()

    @Test
    fun largeQuantitiesStayOnOneLineAndTheScaledEditorIsNotClipped() = runBlocking {
        val item = SaleItem(DocumentID("coffee", "A"), "Coffee", Price(195), Long.MAX_VALUE)
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
        val model = InventoryModel(scope, { MutableStateFlow(listOf(item)) }, { _, _ -> }, { _, _ -> })
        try {
            withContext(Dispatchers.Main) {
                model.setLocation("A")
                model.setVisible(true)
            }
            compose.setContent {
                val density = LocalDensity.current
                CompositionLocalProvider(LocalDensity provides Density(density.density, 3f)) {
                    BrandTheme { InventoryContent(model) { androidx.compose.foundation.layout.Box(Modifier.background(Color.Transparent)) } }
                }
            }
            val displayed = mutableListOf<TextLayoutResult>()
            compose.onNodeWithText(Long.MAX_VALUE.toString()).performSemanticsAction(SemanticsActions.GetTextLayoutResult) { it(displayed) }
            assertEquals(1, displayed.single().lineCount)
            assertTrue(displayed.single().isLineEllipsized(0))
            compose.onNodeWithTag("quantity-coffee").performClick()
            val editor = compose.onNode(hasSetTextAction())
            val editing = mutableListOf<TextLayoutResult>()
            editor.performSemanticsAction(SemanticsActions.GetTextLayoutResult) { it(editing) }
            assertEquals(Long.MAX_VALUE.toString(), editing.single().layoutInput.text.text)
            assertTrue(editor.fetchSemanticsNode().boundsInRoot.height >= editing.single().getLineBottom(0))
        } finally {
            withContext(Dispatchers.Main) { model.setVisible(false) }
            scope.cancel()
        }
    }
}
