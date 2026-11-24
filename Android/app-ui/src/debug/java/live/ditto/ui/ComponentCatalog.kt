package live.ditto.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview

@Composable
fun ComponentCatalog(dark: Boolean = false) {
    var text by remember { mutableStateOf("") }
    var selected by remember { mutableStateOf(true) }
    BrandTheme(dark) {
        Column(Modifier.verticalScroll(rememberScrollState()).padding(AppLayout.padding), verticalArrangement = Arrangement.spacedBy(AppLayout.sectionGap)) {
            AppHeader("Components") { Text("Context", style = androidx.compose.material3.MaterialTheme.typography.bodySmall) }
            Row(horizontalArrangement = Arrangement.spacedBy(AppLayout.gap)) {
                AppButton("PRIMARY", {})
                AppButton("DISABLED", {}, enabled = false)
            }
            AppButton("SECONDARY", {}, secondary = true)
            AppTextButton("TEXT ACTION", {})
            AppField("Name", error = "Enter a name.") { BasicTextField(text, onValueChange = { text = it }) }
            AppRow("Navigation row", onClick = {})
            AppChoiceRow("Selected option", selected, { selected = !selected })
            AppSurface { Text("Surface content") }
            AppSurface(style = AppSurfaceStyle.OUTLINED) { Text("Outlined surface") }
            AppSurface(style = AppSurfaceStyle.COMPACT) { Text("Compact surface") }
            AppCounter(canDecrement = true, decrement = {}, increment = {}) { Text("12") }
            AppWell { Text("Empty region") }
            AppPhoto(null, Modifier.size(AppLayout.thumbnailSize))
            AppPagination("Page 1 of 2", canPrevious = false, canNext = true, previous = {}, next = {})
        }
    }
}

@Preview(widthDp = 720, heightDp = 1000)
@Composable
private fun LightCatalog() {
    ComponentCatalog()
}

@Preview(widthDp = 720, heightDp = 1000, uiMode = android.content.res.Configuration.UI_MODE_NIGHT_YES)
@Composable
private fun DarkCatalog() {
    ComponentCatalog(true)
}

@Preview(widthDp = 420, heightDp = 1000, fontScale = 1.6f)
@Composable
private fun LargeTextCatalog() {
    ComponentCatalog()
}
