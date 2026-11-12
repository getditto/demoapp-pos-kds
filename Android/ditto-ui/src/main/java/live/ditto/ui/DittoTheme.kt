package live.ditto.ui

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

object DittoColors {
    val actionFill = Color(0xFFE7EE00)
    val onAction = Color.Black
}

object DittoLayout {
    val gap = 8.dp
    val padding = 16.dp
    val radius = 16.dp
    val controlHeight = 48.dp
}

object DittoTypography {
    private val bodyFont = FontFamily(Font(R.font.geist))
    private val monoFont = FontFamily(Font(R.font.geist_mono))
    val pageTitle = TextStyle(fontFamily = FontFamily(Font(R.font.chakra_petch_regular)), fontWeight = FontWeight.Normal, fontSize = 28.sp, lineHeight = 34.sp)
    val action = TextStyle(fontFamily = monoFont, fontSize = 14.sp, lineHeight = 20.sp)
    val styles = Typography(
        displayLarge = pageTitle, displayMedium = pageTitle, displaySmall = pageTitle,
        headlineLarge = pageTitle, headlineMedium = pageTitle, headlineSmall = pageTitle,
        titleLarge = TextStyle(fontFamily = bodyFont, fontSize = 22.sp, lineHeight = 28.sp),
        titleMedium = TextStyle(fontFamily = bodyFont, fontSize = 18.sp, lineHeight = 24.sp),
        titleSmall = TextStyle(fontFamily = bodyFont, fontSize = 16.sp, lineHeight = 24.sp),
        bodyLarge = TextStyle(fontFamily = bodyFont, fontSize = 16.sp, lineHeight = 24.sp),
        bodyMedium = TextStyle(fontFamily = bodyFont, fontSize = 14.sp, lineHeight = 20.sp),
        bodySmall = TextStyle(fontFamily = bodyFont, fontSize = 12.sp, lineHeight = 16.sp),
        labelLarge = action, labelMedium = action, labelSmall = action.copy(fontSize = 12.sp, lineHeight = 16.sp)
    )
}

private val lightColors = lightColorScheme(
    surfaceTint = Color.Transparent,
    primary = Color(0xFF0A0A0A), onPrimary = Color.White,
    primaryContainer = Color(0xFFFCFCDD), onPrimaryContainer = Color(0xFF0A0A0A),
    secondary = Color(0xFF525252), onSecondary = Color.White,
    secondaryContainer = Color(0xFFFCFCDD), onSecondaryContainer = Color(0xFF0A0A0A),
    background = Color(0xFFFAFAFA), onBackground = Color(0xFF0A0A0A),
    surface = Color.White, onSurface = Color(0xFF0A0A0A),
    surfaceVariant = Color(0xFFF5F5F5), onSurfaceVariant = Color(0xFF525252),
    surfaceContainer = Color.White, surfaceContainerLow = Color(0xFFF5F5F5),
    surfaceContainerHigh = Color(0xFFE5E5E5), surfaceContainerHighest = Color(0xFFE5E5E5),
    outline = Color(0xFF737373), outlineVariant = Color(0xFFD4D4D4),
    error = Color(0xFFC10007), onError = Color.White, errorContainer = Color(0xFFFFE2E2), onErrorContainer = Color(0xFF82181A)
)
private val darkColors = darkColorScheme(
    surfaceTint = Color.Transparent,
    primary = Color(0xFFFAFAFA), onPrimary = Color.Black,
    primaryContainer = Color(0xFF454800), onPrimaryContainer = Color(0xFFFAFAFA),
    secondary = Color(0xFFD4D4D4), onSecondary = Color.Black,
    secondaryContainer = Color(0xFF454800), onSecondaryContainer = Color(0xFFFAFAFA),
    background = Color(0xFF171717), onBackground = Color(0xFFFAFAFA),
    surface = Color(0xFF262626), onSurface = Color(0xFFFAFAFA),
    surfaceVariant = Color(0xFF404040), onSurfaceVariant = Color(0xFFD4D4D4),
    surfaceContainer = Color(0xFF262626), surfaceContainerLow = Color(0xFF171717),
    surfaceContainerHigh = Color(0xFF404040), surfaceContainerHighest = Color(0xFF525252),
    outline = Color(0xFFA1A1A1), outlineVariant = Color(0xFF525252),
    error = Color(0xFFFF6467), onError = Color.Black, errorContainer = Color(0xFF82181A), onErrorContainer = Color(0xFFFFE2E2)
)

@Composable
fun DittoTheme(darkTheme: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = if (darkTheme) darkColors else lightColors, typography = DittoTypography.styles, content = content)
}
