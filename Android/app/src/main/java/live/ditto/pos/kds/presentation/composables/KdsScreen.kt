package live.ditto.pos.kds.presentation.composables

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.tooling.preview.Preview
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import live.ditto.pos.kds.KDSViewModel

@Composable
fun KdsScreen(
    viewModel: KDSViewModel = hiltViewModel()
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()

    TicketGrid(ticketItems = state.tickets)
}

@Preview
@Composable
private fun KdsScreenPreview() {
    KdsScreen()
}
