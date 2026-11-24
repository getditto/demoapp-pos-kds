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
import live.ditto.pos.settings.AppAppearance
import live.ditto.ui.AppChoiceRow
import live.ditto.ui.AppLayout
import live.ditto.ui.AppRow
import live.ditto.ui.AppSurface
import live.ditto.ui.AppWindowViewModel

@Composable
fun SettingsScreen(location: String, appearance: AppAppearance, version: String, build: String, sdkVersion: String, onAppearance: (AppAppearance) -> Unit, onLocation: () -> Unit, onTools: () -> Unit) {
    val uriHandler = LocalUriHandler.current
    val viewModel = AppWindowViewModel(LocalConfiguration.current.screenWidthDp.toFloat())
    BoxWithConstraints(Modifier.fillMaxSize()) {
        Column(
            Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).heightIn(min = maxHeight).padding(horizontal = viewModel.horizontalPadding, vertical = AppLayout.padding),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(viewModel.sectionSpacing)) {
                AppRow(location, onClick = onLocation, eyebrow = "Location")
                AppSurface(Modifier.fillMaxWidth()) {
                    Column(verticalArrangement = Arrangement.spacedBy(AppLayout.gap)) {
                        Text("Appearance", style = MaterialTheme.typography.bodyMedium)
                        Text("System follows this device’s setting.", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        Column(Modifier.selectableGroup(), verticalArrangement = Arrangement.spacedBy(AppLayout.gap)) {
                            AppAppearance.entries.forEach { item ->
                                AppChoiceRow(
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
                AppRow("Ditto Tools", onClick = onTools)
            }
            Column(Modifier.fillMaxWidth().padding(top = AppLayout.sectionGap), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(AppLayout.smallGap)) {
                Text("Build $version ($build)", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center)
                Text("Powered by Ditto Edge SDK $sdkVersion", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center)
                TextButton(onClick = { uriHandler.openUri("https://ditto.com") }, modifier = Modifier.fillMaxWidth()) {
                    Text("ditto.com", style = MaterialTheme.typography.bodySmall, textDecoration = TextDecoration.Underline)
                }
            }
        }
    }
}
