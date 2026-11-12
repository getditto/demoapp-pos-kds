package live.ditto.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp

@Composable
fun PhotoCatalog(image: ImageBitmap? = null, tablet: Boolean = false, dark: Boolean = false) {
    DittoTheme(dark) {
        Surface(color = MaterialTheme.colorScheme.background) {
            Column(Modifier.background(MaterialTheme.colorScheme.background).padding(DittoLayout.padding), verticalArrangement = Arrangement.spacedBy(24.dp)) {
                Text("Photos", style = DittoTypography.pageTitle)
                Text("Component preview", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Row(horizontalArrangement = Arrangement.spacedBy(DittoLayout.padding)) {
                    PhotoThumbnail(image, if (image == null) "Photo slot" else "With photo", tablet, Modifier.weight(1f))
                    PhotoThumbnail(null, "Placeholder", tablet, Modifier.weight(1f))
                }
                Row(horizontalArrangement = Arrangement.spacedBy(DittoLayout.padding)) {
                    PhotoCard(image, if (image == null) "Photo slot" else "With photo", Modifier.weight(1f))
                    PhotoCard(null, "Placeholder", Modifier.weight(1f))
                }
                Text("Both image slots keep their size as files become available.", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

@Composable
private fun PhotoThumbnail(image: ImageBitmap?, title: String, tablet: Boolean, modifier: Modifier) {
    Row(modifier, horizontalArrangement = Arrangement.spacedBy(DittoLayout.gap), verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
        DittoPhoto(image, Modifier.size(if (tablet) 48.dp else 40.dp))
        Text(title, style = MaterialTheme.typography.bodyMedium)
    }
}

@Composable
private fun PhotoCard(image: ImageBitmap?, title: String, modifier: Modifier) {
    Column(modifier.clip(RoundedCornerShape(DittoLayout.radius)).background(MaterialTheme.colorScheme.surface)) {
        DittoPhoto(image, Modifier.fillMaxWidth().height(112.dp), ContentScale.Fit, cornerRadius = 0.dp)
        Text(title, Modifier.padding(DittoLayout.padding), style = MaterialTheme.typography.bodyLarge)
    }
}

@Preview(widthDp = 420)
@Composable
private fun LightPhotos() {
    PhotoCatalog()
}

@Preview(widthDp = 420, uiMode = android.content.res.Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun DarkPhotos() {
    PhotoCatalog(dark = true)
}

@Preview(widthDp = 720)
@Composable
private fun TabletPhotos() {
    PhotoCatalog(tablet = true)
}
