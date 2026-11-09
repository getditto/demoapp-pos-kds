package live.ditto.pos.settings.presentation

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.unit.dp
import live.ditto.pos.settings.AppAppearance
import live.ditto.ui.DittoRow
import live.ditto.ui.DittoSurface
import live.ditto.ui.R

@Composable
fun SettingsScreen(location: String, appearance: AppAppearance, version: String, build: String, sdkVersion: String, onAppearance: (AppAppearance) -> Unit, onLocation: () -> Unit, onTools: () -> Unit) {
    val uriHandler = LocalUriHandler.current
    val inset = if (LocalConfiguration.current.screenWidthDp >= 600) 24.dp else 16.dp
    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = inset, vertical = 16.dp), verticalArrangement = Arrangement.spacedBy(24.dp)) {
        DittoRow("Location", R.drawable.phosphor_map_pin, onLocation, detail = location)
        DittoSurface(Modifier.fillMaxWidth()) {
            Text("Appearance", style = MaterialTheme.typography.titleMedium)
            SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth().padding(top = 12.dp)) {
                AppAppearance.entries.forEachIndexed { index, item ->
                    SegmentedButton(
                        selected = appearance == item,
                        onClick = { onAppearance(item) },
                        shape = androidx.compose.material3.SegmentedButtonDefaults.itemShape(index, AppAppearance.entries.size),
                        label = {
                            Text(
                                when (item) {
                                    AppAppearance.SYSTEM -> "System"
                                    AppAppearance.LIGHT -> "Light"
                                    AppAppearance.DARK -> "Dark"
                                }
                            )
                        }
                    )
                }
            }
        }
        DittoRow("Ditto Tools", R.drawable.phosphor_gear, onTools)
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("Build $version ($build)", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text("Powered by Ditto Edge SDK $sdkVersion", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            TextButton(onClick = { uriHandler.openUri("https://ditto.com") }) { Text("ditto.com", style = MaterialTheme.typography.bodyMedium) }
        }
    }
}
