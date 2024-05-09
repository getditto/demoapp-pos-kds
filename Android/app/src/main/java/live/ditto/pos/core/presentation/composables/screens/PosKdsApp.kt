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
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.tooling.preview.Preview
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavHostController
import androidx.navigation.compose.rememberNavController
import kotlinx.coroutines.launch
import live.ditto.Ditto
import live.ditto.pos.core.presentation.composables.PosKDSNavigationDrawer
import live.ditto.pos.core.presentation.composables.PosKdsNavigationBar
import live.ditto.pos.core.presentation.navigation.BottomNavItem
import live.ditto.pos.core.presentation.navigation.PosKdsNavHost
import live.ditto.pos.core.presentation.viewmodel.PosKdsViewModel
import live.ditto.pos.ui.theme.DittoPoSKDSDemoTheme

@Composable
fun PosKdsApp(
    viewModel: PosKdsViewModel = hiltViewModel()
) {
    val bottomNavItems = listOf(
        BottomNavItem.PointOfSale,
        BottomNavItem.KitchenDisplay
    )
    PosKdsApp(
        navHostController = rememberNavController(),
        bottomNavItems = bottomNavItems,
        ditto = viewModel.requireDitto()
    )
}

@Composable
private fun PosKdsApp(
    navHostController: NavHostController,
    bottomNavItems: List<BottomNavItem>,
    ditto: Ditto
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
                    bottomNavItems = bottomNavItems,
                    navHostController = navHostController,
                    onNavigationClicked = {
                        scope.launch {
                            drawerState.apply {
                                if (isClosed) open() else close()
                            }
                        }
                    },
                    ditto = ditto
                )
            }
        }
    }
}

@Composable
@OptIn(ExperimentalMaterial3Api::class)
private fun PosKDSScaffold(
    bottomNavItems: List<BottomNavItem>,
    navHostController: NavHostController,
    onNavigationClicked: () -> Unit,
    ditto: Ditto
) {
    Scaffold(
        bottomBar = {
            PosKdsNavigationBar(
                bottomNavItems = bottomNavItems
            ) {
                navHostController.navigate(route = it.route)
            }
        },
        topBar = {
            CenterAlignedTopAppBar(
                title = {
                    Text(text = "McDitto's")
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
                    navHostController = navHostController,
                    ditto = ditto
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
