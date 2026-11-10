package live.ditto.pos.settings.presentation

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import live.ditto.pos.settings.AppAppearance
import live.ditto.ui.DittoChoiceRow
import live.ditto.ui.DittoRow
import live.ditto.ui.DittoSurface

@Composable
fun SettingsScreen(location: String, appearance: AppAppearance, version: String, build: String, sdkVersion: String, onAppearance: (AppAppearance) -> Unit, onLocation: () -> Unit, onTools: () -> Unit) {
    val uriHandler = LocalUriHandler.current
    val tablet = LocalConfiguration.current.screenWidthDp >= 600
    val inset = if (tablet) 24.dp else 16.dp
    BoxWithConstraints(Modifier.fillMaxSize()) {
        Column(
            Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).heightIn(min = maxHeight).padding(horizontal = inset, vertical = 16.dp),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(if (tablet) 16.dp else 12.dp)) {
                DittoRow(location, onClick = onLocation, eyebrow = "Location")
                DittoSurface(Modifier.fillMaxWidth()) {
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text("Appearance", style = MaterialTheme.typography.bodyMedium)
                        Text("System follows this device’s setting.", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        Column(Modifier.selectableGroup(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            AppAppearance.entries.forEach { item ->
                                DittoChoiceRow(
                                    when (item) {
                                        AppAppearance.SYSTEM -> "System"
                                        AppAppearance.LIGHT -> "Light"
                                        AppAppearance.DARK -> "Dark"
                                    },
                                    selected = appearance == item,
                                    onClick = { onAppearance(item) }
                                )
                            }
                        }
                    }
                }
                DittoRow("Ditto Tools", onClick = onTools)
            }
            Column(Modifier.fillMaxWidth().padding(top = 24.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text("Build $version ($build)", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center)
                Text("Powered by Ditto Edge SDK $sdkVersion", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center)
                TextButton(onClick = { uriHandler.openUri("https://ditto.com") }, modifier = Modifier.fillMaxWidth()) {
                    Text("ditto.com", style = MaterialTheme.typography.bodySmall, textDecoration = TextDecoration.Underline)
                }
            }
        }
    }
}
