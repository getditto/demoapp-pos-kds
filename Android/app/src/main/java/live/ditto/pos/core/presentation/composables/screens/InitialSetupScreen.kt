package live.ditto.pos.core.presentation.composables.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.window.Dialog
import androidx.hilt.navigation.compose.hiltViewModel
import live.ditto.pos.LocalActivity
import live.ditto.pos.core.data.locations.Location
import live.ditto.pos.core.presentation.composables.DemoLocationsList
import live.ditto.pos.core.presentation.viewmodel.MainViewModel

@Composable
fun InitialSetupScreen(
    locations: List<Location>,
    mainViewModel: MainViewModel = hiltViewModel(LocalActivity.current)
) {
    Dialog(onDismissRequest = { }) {
        DemoLocationsList(
            locations = locations,
            onDemoLocationSelected = {
                mainViewModel.updateCurrentLocation(locationId = it.id)
            }
        )
    }
}
