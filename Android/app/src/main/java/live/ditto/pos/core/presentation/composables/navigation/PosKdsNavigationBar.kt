package live.ditto.pos.core.presentation.composables.navigation

import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import live.ditto.pos.core.presentation.navigation.BottomNavItem

@Composable
fun PosKdsNavigationBar(
    showDemoLocationsNavItem: Boolean,
    onItemClick: (bottomNavItem: BottomNavItem) -> Unit
) {
    var selectedItemIndex by rememberSaveable {
        mutableIntStateOf(0)
    }

    val bottomNavItems = buildList {
        add(BottomNavItem.PointOfSale)
        add(BottomNavItem.KitchenDisplay)
        if (showDemoLocationsNavItem) {
            add(BottomNavItem.DemoLocationSelection)
        }
    }

    NavigationBar {
        bottomNavItems.forEachIndexed { index, item ->
            NavigationBarItem(
                selected = selectedItemIndex == index,
                onClick = {
                    selectedItemIndex = index
                    onItemClick(item)
                },
                icon = {
                    Icon(
                        imageVector = if (index == selectedItemIndex) {
                            item.selectedIcon
                        } else {
                            item.unselectedIcon
                        },
                        contentDescription = stringResource(id = item.label)
                    )
                },
                label = {
                    Text(text = stringResource(id = item.label))
                }
            )
        }
    }
}

@Preview
@Composable
private fun PosKdsNavigationBarPreview() {
    PosKdsNavigationBar(
        showDemoLocationsNavItem = true,
        onItemClick = { }
    )
}
