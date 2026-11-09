package live.ditto.pos.core.presentation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.hasScrollToNodeAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollToNode
import androidx.compose.ui.unit.dp
import androidx.test.ext.junit.runners.AndroidJUnit4
import live.ditto.pos.core.data.locations.Location
import live.ditto.pos.core.presentation.composables.DemoLocationsList
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class DemoLocationsListTest {
    @get:Rule
    val compose = createComposeRule()

    private val locations = (1..7).map { Location(id = "location-$it", name = "Location $it") }

    // Landscape phones must keep every location reachable.
    @Test
    fun lastLocationIsReachableAndSelectableInAShortSpace() {
        var selected: Location? = null
        compose.setContent {
            Box(Modifier.size(width = 420.dp, height = 300.dp)) {
                DemoLocationsList(locations = locations, onDemoLocationSelected = { selected = it })
            }
        }

        compose.onNode(hasScrollToNodeAction()).performScrollToNode(hasText("Location 7"))
        compose.onNodeWithText("Location 7")
            .assertIsDisplayed()
            .performClick()

        assertEquals("location-7", selected?.id)
    }
}
