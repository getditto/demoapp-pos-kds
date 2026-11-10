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
    DittoTheme(dark) {
        Column(Modifier.verticalScroll(rememberScrollState()).padding(16.dp), verticalArrangement = Arrangement.spacedBy(24.dp)) {
            DittoHeader("Components", location = "Ham's Burgers")
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                DittoButton("PRIMARY", {})
                DittoButton("DISABLED", {}, enabled = false)
            }
            DittoButton("SECONDARY", {}, secondary = true)
            DittoTextButton("TEXT ACTION", {})
            DittoField("Name", error = "Enter a name.") { BasicTextField(text, onValueChange = { text = it }) }
            DittoRow("Ditto Tools", onClick = {})
            DittoChoiceRow("Selected option", selected, { selected = !selected })
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                DittoWell(Modifier.weight(1f)) { DittoEmptyState("No orders preparing", "New orders will appear here.", R.drawable.phosphor_cooking_pot) }
                DittoSurface(Modifier.weight(1f)) {
                    Text("#32B9A42D", style = DittoTypography.action)
                    Text("2 × Burger")
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                DittoSurface(Modifier.weight(1f)) {
                    Text("#32B9A42D", style = DittoTypography.action)
                    Text("2 × Burger")
                }
                DittoWell(Modifier.weight(1f)) { DittoEmptyState("No orders ready", "Completed orders will appear here.", R.drawable.phosphor_cooking_pot) }
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
