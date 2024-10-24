package live.ditto.pos.core.presentation.composables.navigation

import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.DrawerState
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalDrawerSheet
import androidx.compose.material3.ModalNavigationDrawer
import androidx.compose.material3.NavigationDrawerItem
import androidx.compose.material3.NavigationDrawerItemDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.navigation.NavHostController
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import live.ditto.pos.core.presentation.navigation.NavigationDrawerItem
import live.ditto.pos.core.presentation.navigation.NavigationDrawerItem.AdvancedSettingsDrawerItem
import live.ditto.pos.core.presentation.navigation.NavigationDrawerItem.DittoToolsDrawerItem

@Composable
fun PosKDSNavigationDrawer(
    navController: NavHostController,
    drawerState: DrawerState,
    scope: CoroutineScope,
    content: @Composable () -> Unit
) {
    ModalNavigationDrawer(
        drawerState = drawerState,
        drawerContent = {
            NavigationDrawerContent(
                navController = navController,
                drawerState = drawerState,
                scope = scope
            )
        }
    ) {
        content()
    }
}

@Composable
private fun NavigationDrawerContent(
    navController: NavHostController,
    drawerState: DrawerState,
    scope: CoroutineScope
) {
    ModalDrawerSheet {
        Spacer(modifier = Modifier.height(16.dp))
        PosKdsNavigationDrawerItem(
            navigationDrawerItem = DittoToolsDrawerItem,
            scope = scope,
            drawerState = drawerState,
            navController = navController
        )
        Spacer(modifier = Modifier.height(16.dp))
        PosKdsNavigationDrawerItem(
            navigationDrawerItem = AdvancedSettingsDrawerItem,
            scope = scope,
            drawerState = drawerState,
            navController = navController
        )
    }
}

@Composable
private fun PosKdsNavigationDrawerItem(
    navigationDrawerItem: NavigationDrawerItem,
    scope: CoroutineScope,
    drawerState: DrawerState,
    navController: NavHostController
) {
    NavigationDrawerItem(
        modifier = Modifier.padding(NavigationDrawerItemDefaults.ItemPadding),
        label = { Text(text = stringResource(navigationDrawerItem.label)) },
        selected = false,
        onClick = {
            scope.launch {
                drawerState.close()
            }
            navController.navigate(navigationDrawerItem.route)
        },
        icon = {
            Icon(
                imageVector = navigationDrawerItem.icon,
                contentDescription = stringResource(id = navigationDrawerItem.label)
            )
        }
    )
}
