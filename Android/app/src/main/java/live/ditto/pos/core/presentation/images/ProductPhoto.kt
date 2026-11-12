package live.ditto.pos.core.presentation.images

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.ditto.kotlin.DittoStore
import live.ditto.pos.core.data.DocumentID
import live.ditto.pos.core.data.images.PhotoReference
import live.ditto.ui.DittoPhoto

@Composable
fun ProductPhoto(reference: PhotoReference?, owner: DocumentID, store: DittoStore, modifier: Modifier = Modifier, contentScale: ContentScale = ContentScale.Fit, cornerRadius: Dp = 8.dp) {
    val scope = rememberCoroutineScope()
    val loader = remember(store) { PhotoLoader.from(store, scope) }
    ProductPhoto(reference, owner, loader, modifier, contentScale, cornerRadius)
}

@Composable
internal fun ProductPhoto(reference: PhotoReference?, owner: DocumentID, loader: PhotoLoader, modifier: Modifier = Modifier, contentScale: ContentScale = ContentScale.Fit, cornerRadius: Dp = 8.dp) {
    val image by loader.image.collectAsState()
    LaunchedEffect(loader, owner, reference?.id) { loader.update(reference, owner)?.join() }
    DisposableEffect(loader) { onDispose { loader.stop() } }
    DittoPhoto(if (loader.matches(reference)) image?.asImageBitmap() else null, modifier, contentScale, cornerRadius)
}
