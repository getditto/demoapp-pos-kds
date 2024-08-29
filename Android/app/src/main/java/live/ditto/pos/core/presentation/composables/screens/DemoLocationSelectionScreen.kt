package live.ditto.pos.core.presentation.composables.screens

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavHostController
import live.ditto.pos.core.presentation.composables.DemoLocationsList
import live.ditto.pos.core.presentation.viewmodel.CoreViewModel

@Composable
fun DemoLocationSelectionScreen(
    coreViewModel: CoreViewModel = hiltViewModel(),
    navHostController: NavHostController
) {
    DemoLocationsList(
        modifier = Modifier.fillMaxSize(),
        onDemoLocationSelected = {
            coreViewModel.updateCurrentLocation(locationId = it.id)
            navHostController.popBackStack()
        }
    )
}
