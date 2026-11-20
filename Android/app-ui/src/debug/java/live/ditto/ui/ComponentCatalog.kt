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
            Row(horizontalArrangement = Arrangement.spacedBy(AppLayout.padding)) {
                AppPhoto(null, Modifier.size(40.dp))
                AppPhoto(null, Modifier.size(112.dp))
            }
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                AppWell(Modifier.weight(1f)) { Text("No orders preparing") }
                AppTicket("#32B9A42D", listOf("2 × Burger"), true, "2 min ago", true, {}, Modifier.weight(1f))
            }
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                AppTicket("#32B9A42D", listOf("2 × Burger"), false, "2 min ago", false, {}, Modifier.weight(1f))
                AppWell(Modifier.weight(1f)) { Text("No orders ready") }
            }
            AppOrderSummary("Order #1234ABCD", "2 × Burger · 1 × Coffee", "Preparing", AppStatusTone.ACTIVE, "Oct 29, 14:48", "$18.95", expanded = false)
            AppOrderSummary("Order #5678ABCD", "1 × Coffee", "Delivered", AppStatusTone.SUCCESS, "Oct 29, 14:47", "$1.95", expanded = false)
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
