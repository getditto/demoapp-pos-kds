package live.ditto.pos.core.presentation.composables.navigation

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import live.ditto.pos.core.presentation.navigation.BottomNavItem
import live.ditto.ui.AppIcon

@Composable
fun PosKdsNavigationBar(selectedRoute: String?, onItemClick: (BottomNavItem) -> Unit) {
    NavigationBar(containerColor = MaterialTheme.colorScheme.surface) {
        listOf(BottomNavItem.PointOfSale, BottomNavItem.KitchenDisplay, BottomNavItem.Orders, BottomNavItem.Inventory, BottomNavItem.Settings).forEach { item ->
            NavigationBarItem(
                selected = selectedRoute == item.route || (item == BottomNavItem.Settings && selectedRoute?.startsWith("settings/") == true),
                onClick = { onItemClick(item) },
                icon = { AppIcon(item.icon) },
                label = { Text(item.label, style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.Medium, maxLines = 1, overflow = TextOverflow.Ellipsis) },
                colors = NavigationBarItemDefaults.colors(
                    selectedIconColor = MaterialTheme.colorScheme.onSurface,
                    selectedTextColor = MaterialTheme.colorScheme.onSurface,
                    indicatorColor = MaterialTheme.colorScheme.secondaryContainer
                )
            )
        }
    }
}
