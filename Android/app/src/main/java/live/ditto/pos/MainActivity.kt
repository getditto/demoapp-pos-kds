package live.ditto.pos

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import dagger.hilt.android.AndroidEntryPoint
import live.ditto.pos.core.presentation.composables.screens.PosKdsApp
import live.ditto.pos.core.presentation.viewmodel.CoreViewModel

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    private val viewModel: CoreViewModel by viewModels<CoreViewModel>()

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
            PosKdsApp()
        }
    }
}
