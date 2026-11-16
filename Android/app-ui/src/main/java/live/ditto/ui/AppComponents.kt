package live.ditto.ui

import androidx.annotation.DrawableRes
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

@Composable
fun AppIcon(@DrawableRes icon: Int, modifier: Modifier = Modifier, description: String? = null, size: Dp = 24.dp) {
    Icon(painterResource(icon), contentDescription = description, modifier = modifier.size(size))
}

@Composable
fun AppButton(text: String, onClick: () -> Unit, modifier: Modifier = Modifier, enabled: Boolean = true, secondary: Boolean = false) {
    if (secondary) {
        OutlinedButton(
            onClick,
            modifier.heightIn(min = AppLayout.controlHeight),
            enabled = enabled,
            shape = CircleShape,
            colors = ButtonDefaults.outlinedButtonColors(contentColor = MaterialTheme.colorScheme.onSurface),
            border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant)
        ) { Text(text, style = AppTypography.action, textAlign = TextAlign.Center) }
    } else {
        Button(
            onClick,
            modifier.heightIn(min = AppLayout.controlHeight),
            enabled = enabled,
            shape = CircleShape,
            colors = ButtonDefaults.buttonColors(containerColor = AppColors.actionFill, contentColor = AppColors.onAction)
        ) { Text(text, style = AppTypography.action, textAlign = TextAlign.Center) }
    }
}

@Composable
fun AppTextButton(text: String, onClick: () -> Unit, modifier: Modifier = Modifier, enabled: Boolean = true) {
    TextButton(
        onClick,
        modifier.heightIn(min = AppLayout.controlHeight),
        enabled = enabled,
        colors = ButtonDefaults.textButtonColors(contentColor = MaterialTheme.colorScheme.onSurface)
    ) { Text(text, style = AppTypography.action, textAlign = TextAlign.Center) }
}

@Composable
fun AppSurface(modifier: Modifier = Modifier, content: @Composable ColumnScope.() -> Unit) {
    Surface(modifier, shape = RoundedCornerShape(AppLayout.radius), color = MaterialTheme.colorScheme.surface) {
        Column(Modifier.padding(AppLayout.padding), content = content)
    }
}

@Composable
fun AppRow(title: String, @DrawableRes icon: Int? = null, onClick: () -> Unit, modifier: Modifier = Modifier, detail: String? = null, eyebrow: String? = null, outlined: Boolean = false, trailing: @Composable RowScope.() -> Unit = { AppIcon(R.drawable.phosphor_caret_right) }) {
    Surface(
        onClick,
        modifier.fillMaxWidth(),
        shape = RoundedCornerShape(AppLayout.radius),
        color = MaterialTheme.colorScheme.surface,
        border = if (outlined) BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant) else null
    ) {
        Row(Modifier.padding(AppLayout.padding).heightIn(min = if (eyebrow == null) 32.dp else AppLayout.controlHeight), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            icon?.let { AppIcon(it) }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                eyebrow?.let { Text(it, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant) }
                Text(title, style = MaterialTheme.typography.bodyLarge)
                detail?.let { Text(it, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant) }
            }
            trailing()
        }
    }
}

@Composable
fun AppField(label: String, modifier: Modifier = Modifier, error: String? = null, content: @Composable () -> Unit) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(AppLayout.gap)) {
        Text(label, style = MaterialTheme.typography.bodyMedium)
        Box(Modifier.fillMaxWidth().border(1.dp, if (error == null) MaterialTheme.colorScheme.outlineVariant else MaterialTheme.colorScheme.error, RoundedCornerShape(12.dp)).background(MaterialTheme.colorScheme.surface, RoundedCornerShape(12.dp)).padding(12.dp).heightIn(min = AppLayout.controlHeight)) { content() }
        error?.let { Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodyMedium) }
    }
}

@Composable
fun AppChoiceRow(title: String, selected: Boolean, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Row(
        modifier.fillMaxWidth()
            .background(if (selected) MaterialTheme.colorScheme.secondaryContainer else androidx.compose.ui.graphics.Color.Transparent, RoundedCornerShape(8.dp))
            .selectable(selected = selected, role = Role.RadioButton, onClick = onClick)
            .padding(horizontal = 12.dp, vertical = 8.dp).heightIn(min = 32.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        RadioButton(selected = selected, onClick = null)
        Text(title, style = MaterialTheme.typography.bodyLarge)
    }
}

@Composable
fun AppHeader(title: String, modifier: Modifier = Modifier, location: String = "", tablet: Boolean = false) {
    Column(modifier.fillMaxWidth().background(MaterialTheme.colorScheme.background).padding(horizontal = if (tablet) 24.dp else AppLayout.padding, vertical = if (tablet) 16.dp else 0.dp)) {
        Row(Modifier.fillMaxWidth().heightIn(min = if (tablet) 56.dp else 48.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            Icon(painterResource(R.drawable.ditto_symbol), "Ditto", Modifier.size(if (tablet) 28.dp else 24.5.dp, if (tablet) 32.dp else 28.dp))
            if (tablet) Text(title, style = AppTypography.pageTitle)
            if (location.isNotEmpty()) {
                Row(Modifier.weight(1f), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp, Alignment.End)) {
                    AppIcon(R.drawable.phosphor_map_pin, size = 18.dp)
                    Text(location, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
        if (!tablet) {
            Box(Modifier.heightIn(min = 64.dp), contentAlignment = Alignment.CenterStart) { Text(title, style = AppTypography.pageTitle) }
        }
    }
}

enum class AppEmptyStateStyle { STANDARD, SUCCESS, LARGE }

@Composable
fun AppEmptyState(title: String, message: String, @DrawableRes icon: Int, modifier: Modifier = Modifier, style: AppEmptyStateStyle = AppEmptyStateStyle.STANDARD) {
    Box(modifier.fillMaxSize().padding(24.dp), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(if (style == AppEmptyStateStyle.LARGE) 16.dp else 12.dp)) {
            CompositionLocalProvider(
                LocalContentColor provides when (style) {
                    AppEmptyStateStyle.LARGE -> MaterialTheme.colorScheme.onSurface
                    AppEmptyStateStyle.SUCCESS -> AppColors.success
                    AppEmptyStateStyle.STANDARD -> MaterialTheme.colorScheme.onSurfaceVariant
                }
            ) {
                AppIcon(
                    icon,
                    size = when (style) {
                        AppEmptyStateStyle.LARGE -> 64.dp
                        AppEmptyStateStyle.SUCCESS -> 40.dp
                        AppEmptyStateStyle.STANDARD -> 56.dp
                    }
                )
            }
            Text(title, style = if (style == AppEmptyStateStyle.STANDARD) MaterialTheme.typography.titleMedium else MaterialTheme.typography.titleLarge, textAlign = TextAlign.Center)
            Text(message, style = if (style == AppEmptyStateStyle.STANDARD) MaterialTheme.typography.bodyMedium else MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center)
        }
    }
}

@Composable
fun AppWell(modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Surface(
        modifier.heightIn(min = 160.dp),
        shape = RoundedCornerShape(AppLayout.radius),
        color = MaterialTheme.colorScheme.background,
        border = BorderStroke(1.dp, AppColors.subtleBorder)
    ) { Box(Modifier.fillMaxWidth().padding(24.dp), contentAlignment = Alignment.Center) { content() } }
}
