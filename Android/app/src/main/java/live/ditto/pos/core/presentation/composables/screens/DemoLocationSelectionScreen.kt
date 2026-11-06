package live.ditto.pos.core.presentation.composables.screens

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavHostController
import live.ditto.pos.LocalActivity
import live.ditto.pos.core.presentation.composables.DemoLocationsList
import live.ditto.pos.core.presentation.viewmodel.MainViewModel

@Composable
fun DemoLocationSelectionScreen(
    mainViewModel: MainViewModel = hiltViewModel(LocalActivity.current),
    navHostController: NavHostController
) {
    val state by mainViewModel.uiState.collectAsStateWithLifecycle(minActiveState = Lifecycle.State.RESUMED)

    if (state.isLoading) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
        return
    }

    DemoLocationsList(
        locations = state.locations,
        modifier = Modifier.fillMaxSize(),
        onDemoLocationSelected = {
            mainViewModel.updateCurrentLocation(locationId = it.id)
            navHostController.popBackStack()
        }
    )
}
