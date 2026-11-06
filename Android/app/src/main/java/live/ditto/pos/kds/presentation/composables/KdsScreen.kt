package live.ditto.pos.kds.presentation.composables

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import live.ditto.pos.kds.KDSViewModel

@Composable
fun KdsScreen(
    viewModel: KDSViewModel = hiltViewModel()
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle(minActiveState = Lifecycle.State.RESUMED)

    if (state.isLoading) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
        return
    }

    TicketGrid(
        ticketItems = state.tickets,
        onTicketClicked = { orderId ->
            viewModel.updateTicketStatus(orderId)
        }
    )
}

@Preview
@Composable
private fun KdsScreenPreview() {
    KdsScreen()
}
