package live.ditto.pos

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import dagger.hilt.android.AndroidEntryPoint
import live.ditto.pos.core.presentation.composables.screens.PosKdsApp
import live.ditto.pos.core.presentation.viewmodel.PosKdsViewModel
import live.ditto.transports.DittoSyncPermissions

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    private val viewModel: PosKdsViewModel by viewModels<PosKdsViewModel>()

    private val requestPermissionLauncher = registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) {
        viewModel.requireDitto().refreshPermissions()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        checkDittoPermissions()

        setContent {
            PosKdsApp()
        }
    }

    private fun checkDittoPermissions() {
        val missing = DittoSyncPermissions(this).missingPermissions()
        if (missing.isNotEmpty()) {
            requestPermissionLauncher.launch(missing)
        }
    }
}
