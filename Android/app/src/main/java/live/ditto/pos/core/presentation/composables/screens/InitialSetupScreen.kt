package live.ditto.pos.core.presentation.composables.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.window.Dialog
import androidx.hilt.navigation.compose.hiltViewModel
import live.ditto.pos.core.presentation.composables.DemoLocationsList
import live.ditto.pos.core.presentation.viewmodel.MainViewModel

@Composable
fun InitialSetupScreen(
    mainViewModel: MainViewModel = hiltViewModel()
) {
    Dialog(onDismissRequest = { }) {
        DemoLocationsList(
            onDemoLocationSelected = {
                mainViewModel.updateCurrentLocation(locationId = it.id)
            }
        )
    }
}
