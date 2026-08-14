package live.ditto.pos.core.presentation.composables.screens

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavHostController
import live.ditto.pos.LocalActivity
import live.ditto.pos.core.presentation.composables.DemoLocationsList
import live.ditto.pos.core.presentation.viewmodel.MainViewModel

@Composable
fun DemoLocationSelectionScreen(
    mainViewModel: MainViewModel = hiltViewModel(LocalActivity.current),
    navHostController: NavHostController
) {
    DemoLocationsList(
        modifier = Modifier.fillMaxSize(),
        onDemoLocationSelected = {
            mainViewModel.updateCurrentLocation(locationId = it.id)
            navHostController.popBackStack()
        }
    )
}
