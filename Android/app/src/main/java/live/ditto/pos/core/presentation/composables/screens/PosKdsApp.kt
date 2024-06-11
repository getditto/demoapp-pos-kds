package live.ditto.pos.core.presentation.composables.screens

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.DrawerValue
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberDrawerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.tooling.preview.Preview
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavHostController
import androidx.navigation.compose.rememberNavController
import kotlinx.coroutines.launch
import live.ditto.pos.core.presentation.composables.PosKDSNavigationDrawer
import live.ditto.pos.core.presentation.composables.PosKdsNavigationBar
import live.ditto.pos.core.presentation.navigation.PosKdsNavHost
import live.ditto.pos.core.presentation.viewmodel.CoreViewModel
import live.ditto.pos.ui.theme.DittoPoSKDSDemoTheme

@Composable
fun PosKdsApp(
    viewModel: CoreViewModel = hiltViewModel()
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()

    if (state.isSetupValid) {
        PosKdsApp(
            navHostController = rememberNavController()
        )
    } else {
        InitialSetupScreen()
    }
}

@Composable
private fun PosKdsApp(
    navHostController: NavHostController
) {
    val drawerState = rememberDrawerState(initialValue = DrawerValue.Closed)
    val scope = rememberCoroutineScope()

    DittoPoSKDSDemoTheme {
        Surface {
            PosKDSNavigationDrawer(
                navController = navHostController,
                drawerState = drawerState,
                scope = scope
            ) {
                PosKDSScaffold(
                    navHostController = navHostController
                ) {
                    scope.launch {
                        drawerState.apply {
                            if (isClosed) open() else close()
                        }
                    }
                }
            }
        }
    }
}

@Composable
@OptIn(ExperimentalMaterial3Api::class)
private fun PosKDSScaffold(
    viewModel: CoreViewModel = hiltViewModel(),
    navHostController: NavHostController,
    onNavigationClicked: () -> Unit
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()

    Scaffold(
        bottomBar = {
            PosKdsNavigationBar(
                onItemClick = {
                    navHostController.navigate(route = it.route)
                }
            )
        },
        topBar = {
            CenterAlignedTopAppBar(
                title = {
                    Text(text = state.currentLocationName)
                },
                colors = TopAppBarDefaults
                    .centerAlignedTopAppBarColors(containerColor = Color.LightGray),
                navigationIcon = {
                    IconButton(onClick = { onNavigationClicked() }) {
                        Icon(imageVector = Icons.Filled.Menu, contentDescription = "Menu")
                    }
                }
            )
        },
        content = {
            Surface(modifier = Modifier.padding(it)) {
                PosKdsNavHost(
                    navHostController = navHostController
                )
            }
        }
    )
}

@Preview
@Composable
private fun PosKdsAppPreview() {
    PosKdsApp()
}
