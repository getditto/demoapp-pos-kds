package live.ditto.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
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
import androidx.compose.ui.unit.dp

@Composable
fun ComponentCatalog(dark: Boolean = false) {
    var text by remember { mutableStateOf("") }
    var selected by remember { mutableStateOf(true) }
    BrandTheme(dark) {
        Column(Modifier.verticalScroll(rememberScrollState()).padding(16.dp), verticalArrangement = Arrangement.spacedBy(24.dp)) {
            AppHeader("Components", location = "Ham's Burgers")
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                AppButton("PRIMARY", {})
                AppButton("DISABLED", {}, enabled = false)
            }
            AppButton("SECONDARY", {}, secondary = true)
            AppTextButton("TEXT ACTION", {})
            AppField("Name", error = "Enter a name.") { BasicTextField(text, onValueChange = { text = it }) }
            AppRow("Ditto Tools", onClick = {})
            AppChoiceRow("Selected option", selected, { selected = !selected })
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                AppWell(Modifier.weight(1f)) { AppEmptyState("No orders preparing", "New orders will appear here.", R.drawable.phosphor_cooking_pot) }
                AppSurface(Modifier.weight(1f)) {
                    Text("#32B9A42D", style = AppTypography.action)
                    Text("2 × Burger")
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                AppSurface(Modifier.weight(1f)) {
                    Text("#32B9A42D", style = AppTypography.action)
                    Text("2 × Burger")
                }
                AppWell(Modifier.weight(1f)) { AppEmptyState("No orders ready", "Completed orders will appear here.", R.drawable.phosphor_cooking_pot) }
            }
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
