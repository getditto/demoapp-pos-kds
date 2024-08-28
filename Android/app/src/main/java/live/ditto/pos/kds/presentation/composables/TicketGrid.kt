package live.ditto.pos.kds.presentation.composables

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import live.ditto.pos.core.data.demoTicketItems
import live.ditto.pos.core.data.orders.OrderStatus
import live.ditto.pos.kds.TicketItemUi
import live.ditto.pos.ui.theme.CanceledStatusTicketColor
import live.ditto.pos.ui.theme.DeliveredStatusTicketColor
import live.ditto.pos.ui.theme.InProcessStatusTicketColor
import live.ditto.pos.ui.theme.OpenStatusTicketColor
import live.ditto.pos.ui.theme.ProcessedStatusTicketColor

@Composable
fun TicketGrid(
    ticketItems: List<TicketItemUi>,
    onTicketClicked: (orderId: String) -> Unit
) {
    LazyVerticalGrid(
        columns = GridCells.Adaptive(200.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        contentPadding = PaddingValues(8.dp)
    ) {
        items(ticketItems) { ticketItem ->
            TicketItem(
                ticketItemUi = ticketItem,
                onTicketClicked = onTicketClicked
            )
        }
    }
}

@Composable
fun TicketItem(
    ticketItemUi: TicketItemUi,
    onTicketClicked: (orderId: String) -> Unit
) {
    Card(
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceContainer
        ),
        onClick = { onTicketClicked(ticketItemUi.orderId) }
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
        ) {
            val ticketColor = when (ticketItemUi.orderStatus) {
                OrderStatus.OPEN -> OpenStatusTicketColor
                OrderStatus.IN_PROCESS -> InProcessStatusTicketColor
                OrderStatus.PROCESSED -> ProcessedStatusTicketColor
                OrderStatus.DELIVERED -> DeliveredStatusTicketColor
                OrderStatus.CANCELED -> CanceledStatusTicketColor
            }
            TicketHeader(
                headerText = ticketItemUi.header,
                ticketColor = ticketColor
            )
            TicketItems(ticketItemUi.items)
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(28.dp)
                    .background(color = ticketColor)
            ) {
                if (ticketItemUi.isPaid) {
                    val icon = Icons.Outlined.CheckCircle
                    Image(
                        modifier = Modifier
                            .padding(4.dp)
                            .align(Alignment.CenterEnd),
                        imageVector = icon,
                        contentDescription = "Check Mark"
                    )
                }
            }
        }
    }
}

@Composable
private fun TicketItems(itemsMap: HashMap<String, Int>) {
    Column(modifier = Modifier.padding(4.dp)) {
        itemsMap.keys.forEachIndexed { index, name ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = name,
                    textAlign = TextAlign.Left
                )
                Text(
                    text = itemsMap[name].toString(),
                    textAlign = TextAlign.Right
                )
            }
            if (index != itemsMap.keys.size - 1) {
                HorizontalDivider(
                    thickness = 1.dp,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }
        }
    }
}

@Composable
private fun TicketHeader(
    headerText: String,
    ticketColor: Color
) {
    Box(modifier = Modifier.background(color = ticketColor)) {
        Text(
            text = headerText,
            modifier = Modifier
                .fillMaxWidth()
                .padding(4.dp),
            textAlign = TextAlign.Center
        )
    }
}

@Preview
@Composable
private fun TicketItemsPreview() {
    TicketItems(itemsMap = demoTicketItems.first().items)
}

@Preview
@Composable
private fun TicketHeaderPreview() {
    TicketHeader(headerText = "Header Text", OpenStatusTicketColor)
}

@Preview
@Composable
private fun TicketItemPreview() {
    TicketItem(
        ticketItemUi = demoTicketItems.first(),
        onTicketClicked = {}
    )
}

@Preview
@Composable
private fun TicketGridPreview() {
    TicketGrid(
        ticketItems = demoTicketItems,
        onTicketClicked = {}
    )
}
