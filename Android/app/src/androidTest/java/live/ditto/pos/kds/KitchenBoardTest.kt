package live.ditto.pos.kds

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.unit.dp
import live.ditto.pos.core.data.OrderStatus
import live.ditto.pos.kds.presentation.composables.TicketGrid
import live.ditto.ui.DittoTheme
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import kotlin.time.Instant

class KitchenBoardTest {
    @get:Rule val compose = createComposeRule()

    @Test
    fun actionsTargetTheRightOrderAndWaitForObservedDataToMoveIt() {
        val preparing = ticket("PREP0001", OrderStatus.IN_PROCESS)
        val ready = ticket("READY001", OrderStatus.PROCESSED)
        var observed by mutableStateOf(listOf(preparing, ready))
        val actions = mutableListOf<String>()
        compose.setContent { DittoTheme { TicketGrid(observed, actions::add) } }
        compose.onNodeWithContentDescription("Mark ready, #PREP0001").performClick()
        compose.onNodeWithContentDescription("Complete order, #READY001").performClick()
        compose.runOnIdle { assertEquals(listOf("PREP0001", "READY001"), actions) }
        compose.onNodeWithContentDescription("Mark ready, #PREP0001").assertExists()
        compose.runOnIdle { observed = listOf(preparing.copy(orderStatus = OrderStatus.PROCESSED)) }
        compose.onNodeWithContentDescription("Mark ready, #PREP0001").assertDoesNotExist()
        compose.onNodeWithContentDescription("Complete order, #PREP0001").performClick()
        compose.runOnIdle {
            assertEquals("PREP0001", actions.last())
            observed = emptyList()
        }
        compose.onNodeWithText("No active orders").assertExists()
    }

    @Test
    fun tabletShowsOnlyTheEmptyHalfAndPhoneNeverShowsPartialWells() {
        val preparing = ticket("PREP0001", OrderStatus.IN_PROCESS)
        val ready = ticket("READY001", OrderStatus.PROCESSED)
        var observed by mutableStateOf(listOf(ready))
        var tablet by mutableStateOf(true)
        compose.setContent {
            DittoTheme { Box(Modifier.width(if (tablet) 1024.dp else 393.dp)) { TicketGrid(observed) {} } }
        }
        compose.onNodeWithText("No orders preparing").assertExists()
        compose.onNodeWithContentDescription("Complete order, #READY001").assertExists()
        compose.runOnIdle { observed = listOf(preparing) }
        compose.onNodeWithText("No orders preparing").assertDoesNotExist()
        compose.onNodeWithText("No orders ready").assertExists()
        compose.onNodeWithContentDescription("Mark ready, #PREP0001").assertExists()
        compose.runOnIdle { tablet = false }
        compose.onNodeWithText("No orders ready").assertDoesNotExist()
        compose.onNodeWithContentDescription("Mark ready, #PREP0001").assertExists()
        compose.runOnIdle {
            tablet = true
            observed = emptyList()
        }
        compose.onNodeWithText("No orders preparing").assertDoesNotExist()
        compose.onNodeWithText("No orders ready").assertDoesNotExist()
        compose.onNodeWithText("No active orders").assertExists()
        compose.onNodeWithText("Preparing · 0").assertExists()
        compose.onNodeWithText("Ready · 0").assertExists()
    }

    private fun ticket(id: String, status: OrderStatus) = TicketItemUi(
        Instant.parse("2026-11-12T12:00:00Z"),
        id,
        hashMapOf("Burger" to 2),
        false,
        status,
        id
    )
}
