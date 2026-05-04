package live.ditto.pos.core.presentation.composables.screens

import androidx.compose.runtime.Composable
import androidx.compose.ui.window.Dialog
import androidx.hilt.navigation.compose.hiltViewModel
import live.ditto.pos.core.presentation.composables.DemoLocationsList
import live.ditto.pos.core.presentation.viewmodel.CoreViewModel

@Composable
fun InitialSetupScreen(
    coreViewModel: CoreViewModel = hiltViewModel()
) {
    Dialog(onDismissRequest = { }) {
        DemoLocationsList(
            onDemoLocationSelected = {
                coreViewModel.updateCurrentLocation(locationId = it.id)
            }
        )
    }
}
