package live.ditto.pos.kds.presentation.composables

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp

@Composable
fun TicketGrid() {
    LazyVerticalGrid(
        columns = GridCells.Adaptive(200.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        contentPadding = PaddingValues(8.dp)
    ) {
        val ticketItems = listOf(
            TicketItemUi(
                header = "9:59 AM #8921DD",
                items = hashMapOf(
                    "Burger" to 1,
                    "Coffee" to 1,
                    "Milk" to 3
                )
            ),
            TicketItemUi(
                header = "9:56 AM #09FBC2",
                items = hashMapOf(
                    "Fruit Salad" to 2,
                    "Coffee" to 1,
                    "Corn" to 1,
                    "Cereal" to 5
                )
            )
        )
        items(ticketItems) { ticketItem ->
            TicketItem(ticketItemUi = ticketItem)
        }
    }
}

@Composable
fun TicketItem(ticketItemUi: TicketItemUi) {
    Card(
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceContainer
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
        ) {
            Box(modifier = Modifier.background(color = MaterialTheme.colorScheme.inverseOnSurface)) {
                Text(
                    text = ticketItemUi.header,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(4.dp),
                    textAlign = TextAlign.Center
                )
            }
            Column(modifier = Modifier.padding(4.dp)) {
                ticketItemUi.items.keys.forEachIndexed { index, name ->
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = name,
                            textAlign = TextAlign.Left
                        )
                        Text(
                            text = ticketItemUi.items[name].toString(),
                            textAlign = TextAlign.Right
                        )
                    }
                    if (index != ticketItemUi.items.keys.size - 1) {
                        HorizontalDivider(
                            thickness = 1.dp,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                    }
                }
            }
        }
    }
}

data class TicketItemUi(
    val header: String,
    val items: HashMap<String, Int>
)

@Preview
@Composable
private fun TicketItemPreview() {
}

@Preview
@Composable
private fun TicketGridPreview() {
}
