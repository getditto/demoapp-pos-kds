package live.ditto.pos.kds.presentation.composables

import androidx.compose.runtime.Composable
import androidx.compose.ui.tooling.preview.Preview
import live.ditto.pos.core.data.demoTicketItems

@Composable
fun KdsScreen() {
    TicketGrid(ticketItems = demoTicketItems)
}

@Preview
@Composable
private fun KdsScreenPreview() {
    KdsScreen()
}
