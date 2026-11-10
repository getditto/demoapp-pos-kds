package live.ditto.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

@Composable
fun DittoPhoto(image: ImageBitmap?, modifier: Modifier = Modifier, contentScale: ContentScale = ContentScale.Fit, cornerRadius: Dp = 8.dp, iconSize: Dp = 24.dp) {
    Box(modifier.clip(RoundedCornerShape(cornerRadius)).background(MaterialTheme.colorScheme.surface), contentAlignment = Alignment.Center) {
        if (image != null) {
            Image(image, null, Modifier.fillMaxSize(), contentScale = contentScale)
        } else {
            CompositionLocalProvider(LocalContentColor provides MaterialTheme.colorScheme.onSurfaceVariant) {
                DittoIcon(R.drawable.phosphor_image, description = null, size = iconSize)
            }
        }
    }
}
