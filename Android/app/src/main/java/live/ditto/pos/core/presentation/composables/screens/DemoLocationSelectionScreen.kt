package live.ditto.pos.core.presentation.composables.screens

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import live.ditto.pos.core.presentation.composables.DemoLocationsList

@Composable
fun DemoLocationSelectionScreen() {
    DemoLocationsList(
        modifier = Modifier.fillMaxSize(),
        onDemoLocationSelected = { }
    )
}
