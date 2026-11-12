package live.ditto.pos.core.presentation.images

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.ditto.kotlin.DittoStore
import live.ditto.pos.core.data.CartLineItem
import live.ditto.pos.core.data.DocumentID

@Composable
fun OrderLinePhoto(line: CartLineItem, orderId: DocumentID, store: DittoStore, modifier: Modifier = Modifier) {
    ProductPhoto(line.image, orderId, store, modifier)
}
