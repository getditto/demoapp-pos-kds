package live.ditto.pos.core.presentation

import android.content.res.Configuration
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.StateRestorationTester
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextInput
import androidx.datastore.preferences.core.PreferenceDataStoreFactory
import androidx.test.platform.app.InstrumentationRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.job
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import live.ditto.pos.core.presentation.composables.screens.PosKdsShell
import live.ditto.pos.core.presentation.viewmodel.AppState
import live.ditto.pos.settings.AppAppearance
import live.ditto.pos.settings.AppSettings
import live.ditto.pos.ui.theme.AppTheme
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import java.io.File
import java.util.UUID

class AppearanceAndNavigationTest {
    @get:Rule val compose = createComposeRule()

    @Test
    fun rootThemeTracksSystemOverrideAndDiskRelaunchWhileKeepingDestinationAndDraft() = runBlocking {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val file = File(context.cacheDir, "appearance-${UUID.randomUUID()}.preferences_pb")
        var storeScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
        var settings by mutableStateOf(AppSettings(PreferenceDataStoreFactory.create(scope = storeScope, produceFile = { file })))
        val configuration = mutableStateOf(Configuration(context.resources.configuration).apply { uiMode = Configuration.UI_MODE_NIGHT_NO })
        var isDark = false
        var renderedStore: AppSettings? = null
        var renderedAppearance: AppAppearance? = null
        val restoration = StateRestorationTester(compose)
        try {
            settings.setLocationId("00001")
            settings.setCurrentOrderId("open-cart")
            restoration.setContent {
                val observed by remember(settings) {
                    val source = settings
                    source.appearanceFlow().map { source to it }
                }.collectAsState(initial = null)
                val appearance = observed?.second ?: AppAppearance.SYSTEM
                val scope = rememberCoroutineScope()
                CompositionLocalProvider(LocalConfiguration provides configuration.value) {
                    AppTheme(appearance) {
                        val dark = MaterialTheme.colorScheme.background.luminance() < 0.5f
                        SideEffect {
                            isDark = dark
                            renderedStore = observed?.first
                            renderedAppearance = observed?.second
                        }
                        PosKdsShell(
                            state = AppState("Ham's Burgers", emptyList(), currentLocationId = "00001"), needsLocation = false,
                            appearance = appearance, version = "1", build = "9999", sdkVersion = "5.2.0",
                            onAppearance = { selection -> scope.launch { settings.setAppearance(selection) } },
                            onLocation = { _, done -> done() },
                            pos = {
                                var draft by rememberSaveable { mutableStateOf("") }
                                TextField(draft, onValueChange = { draft = it }, label = { Text("Draft") })
                            },
                            kds = { Text("Kitchen content") }, tools = { Text("Tools destination") }
                        )
                    }
                }
            }
            compose.onNodeWithText("Draft").performTextInput("retained")
            compose.onNode(hasText("Settings") and hasClickAction()).performClick()
            compose.onNodeWithText("Appearance").assertExists()
            compose.waitUntil { !isDark }
            compose.runOnIdle { configuration.value = Configuration(configuration.value).apply { uiMode = Configuration.UI_MODE_NIGHT_YES } }
            compose.waitUntil { isDark }
            compose.onNodeWithText("Light").performClick()
            compose.waitUntil { !isDark }
            compose.runOnIdle { configuration.value = Configuration(configuration.value).apply { uiMode = Configuration.UI_MODE_NIGHT_NO } }
            compose.waitForIdle()
            compose.runOnIdle { configuration.value = Configuration(configuration.value).apply { uiMode = Configuration.UI_MODE_NIGHT_YES } }
            compose.waitForIdle()
            assertEquals(false, isDark)
            compose.onNodeWithText("System").performClick()
            compose.waitUntil { isDark }
            compose.onNodeWithText("Dark").performClick()
            compose.waitUntil { renderedAppearance == AppAppearance.DARK && isDark }
            storeScope.coroutineContext.job.cancelAndJoin()
            storeScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
            val reopened = AppSettings(PreferenceDataStoreFactory.create(scope = storeScope, produceFile = { file }))
            compose.runOnIdle {
                settings = reopened
                configuration.value = Configuration(configuration.value).apply { uiMode = Configuration.UI_MODE_NIGHT_NO }
            }
            compose.waitUntil { renderedStore === reopened && renderedAppearance == AppAppearance.DARK && isDark }
            restoration.emulateSavedInstanceStateRestore()
            compose.waitUntil { renderedStore === reopened && renderedAppearance == AppAppearance.DARK && isDark }
            compose.onNodeWithText("Appearance").assertExists()
            compose.onNode(hasText("POS") and hasClickAction()).performClick()
            compose.onNodeWithText("retained").assertExists()
            assertEquals("00001", settings.locationId())
            assertEquals("open-cart", settings.currentOrderId())
        } finally {
            storeScope.coroutineContext.job.cancelAndJoin()
            file.delete()
        }
    }
}
