package live.ditto.pos.orders

import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import live.ditto.pos.core.data.DocumentID
import live.ditto.pos.core.data.TestDitto
import live.ditto.pos.core.data.orders.OrdersHistory
import live.ditto.pos.core.presentation.composables.screens.PosKdsShell
import live.ditto.pos.core.presentation.viewmodel.AppState
import live.ditto.pos.settings.AppAppearance
import live.ditto.ui.BrandTheme
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

class OrdersLiveViewTest {
    @get:Rule val compose = createComposeRule()

    @Test
    fun visiblePaginationRespondsToInsertedAndClearedOrders(): Unit = runBlocking {
        TestDitto.withInstance {
            val repository = repository()
            val fixture = TestDitto.fixture()
            fun order(index: Int) = fixture.copy(documentId = DocumentID("%08d".format(index), "A"))
            repeat(100) { insert(order(it)) }
            val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
            val history = OrdersHistory(scope, repository::observeHistoryPage, repository::observeHistoryCount)
            try {
                withContext(Dispatchers.Main) {
                    history.setLocation("A")
                    history.setVisible(true)
                }
                withTimeout(5000) { history.state.first { it.total == 100 && it.orders.size == 50 } }
                compose.setContent {
                    val state by history.state.collectAsState()
                    BrandTheme {
                        PosKdsShell(
                            state = AppState("Ham's Burgers", emptyList(), currentLocationId = "A"), needsLocation = false,
                            appearance = AppAppearance.LIGHT, version = "1", build = "9999", sdkVersion = "5.2.0",
                            onAppearance = {}, onLocation = { _, done -> done() },
                            pos = {}, kds = {}, orders = { OrdersContent(state, history::previous, history::next) }, tools = {},
                            startDestination = "orders"
                        )
                    }
                }
                compose.onNodeWithText("Page 1 of 2").assertExists()
                compose.onNodeWithText("PREVIOUS").assertIsNotEnabled()
                compose.onNodeWithText("NEXT").performClick()
                compose.waitUntil { history.state.value.pageIndex == 1 && history.state.value.orders.size == 50 }
                compose.onNodeWithText("Page 2 of 2").assertExists()
                compose.onNodeWithText("NEXT").assertIsNotEnabled()
                insert(order(100))
                compose.waitUntil { history.state.value.total == 101 }
                compose.onNodeWithText("Page 2 of 3").assertExists()
                compose.onNodeWithText("NEXT").assertIsEnabled().performClick()
                compose.waitUntil { history.state.value.pageIndex == 2 && history.state.value.orders.size == 1 }
                compose.onNodeWithText("Page 3 of 3").assertExists()
                val last = history.state.value.orders.single()
                repository.clearCart(last)
                compose.waitUntil { history.state.value.total == 100 && history.state.value.pageIndex == 1 && history.state.value.orders.size == 50 }
                assertEquals(50, history.state.value.orders.size)
                compose.onNodeWithText("Page 2 of 2").assertExists()
                compose.onNodeWithText("NEXT").assertIsNotEnabled()
                compose.onNodeWithText("PREVIOUS").assertIsEnabled()
            } finally {
                withContext(Dispatchers.Main) { history.setVisible(false) }
                scope.cancel()
            }
        }
    }
}
