package live.ditto.pos

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import dagger.hilt.android.AndroidEntryPoint
import live.ditto.pos.core.presentation.composables.screens.PosKdsApp
import live.ditto.pos.core.presentation.viewmodel.MainViewModel
import live.ditto.pos.ui.theme.DittoPoSKDSDemoTheme

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
                DittoPoSKDSDemoTheme {
                    PosKdsApp()
                }
            }
        }
    }
}
