package live.ditto.pos

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import dagger.hilt.android.AndroidEntryPoint
import live.ditto.pos.core.presentation.composables.screens.PosKdsApp
import live.ditto.pos.core.presentation.viewmodel.MainViewModel
import live.ditto.pos.ui.theme.AppTheme
import live.ditto.pos.ui.theme.isDark

val LocalActivity = staticCompositionLocalOf<ComponentActivity> {
    error("LocalActivity is not present")
}

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    private val viewModel: MainViewModel by viewModels<MainViewModel>()

    private val requestPermissionLauncher = registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) {
        viewModel.refreshDittoPermissions()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        viewModel.checkDittoPermissions { missingPermissions ->
            if (missingPermissions.isNotEmpty()) {
                requestPermissionLauncher.launch(missingPermissions)
            }
        }

        setContent {
            CompositionLocalProvider(LocalActivity provides this@MainActivity) {
                val appearance by viewModel.appearance.collectAsStateWithLifecycle()
                appearance?.let { selected ->
                    val dark = selected.isDark(isSystemInDarkTheme())
                    SideEffect {
                        enableEdgeToEdge(
                            statusBarStyle = SystemBarStyle.auto(android.graphics.Color.TRANSPARENT, android.graphics.Color.TRANSPARENT) { dark },
                            navigationBarStyle = SystemBarStyle.auto(android.graphics.Color.TRANSPARENT, android.graphics.Color.TRANSPARENT) { dark }
                        )
                    }
                    AppTheme(selected) { PosKdsApp() }
                }
            }
        }
    }
}
