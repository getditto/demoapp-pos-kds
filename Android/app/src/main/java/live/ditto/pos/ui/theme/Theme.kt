package live.ditto.pos.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.Composable
import live.ditto.pos.settings.AppAppearance
import live.ditto.ui.BrandTheme

@Composable
fun AppTheme(appearance: AppAppearance, systemDark: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    BrandTheme(darkTheme = appearance.isDark(systemDark), content = content)
}

fun AppAppearance.isDark(systemDark: Boolean): Boolean = when (this) {
    AppAppearance.SYSTEM -> systemDark
    AppAppearance.LIGHT -> false
    AppAppearance.DARK -> true
}

@Composable
fun DemoTheme(content: @Composable () -> Unit) {
    BrandTheme(content = content)
}
