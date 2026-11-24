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
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp

@Composable
fun AppIcon(@DrawableRes icon: Int, modifier: Modifier = Modifier, description: String? = null, size: Dp = AppLayout.iconSize) {
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
            border = BorderStroke(AppLayout.borderWidth, MaterialTheme.colorScheme.outlineVariant)
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
        border = if (outlined) BorderStroke(AppLayout.borderWidth, MaterialTheme.colorScheme.outlineVariant) else null
    ) {
        Row(Modifier.padding(AppLayout.padding).heightIn(min = AppRowViewModel(eyebrow).minimumHeight), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(AppLayout.mediumGap)) {
            icon?.let { AppIcon(it) }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(AppLayout.smallGap)) {
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
        Box(Modifier.fillMaxWidth().border(AppLayout.borderWidth, if (error == null) MaterialTheme.colorScheme.outlineVariant else MaterialTheme.colorScheme.error, RoundedCornerShape(AppLayout.buttonRadius)).background(MaterialTheme.colorScheme.surface, RoundedCornerShape(AppLayout.buttonRadius)).padding(AppLayout.mediumGap).heightIn(min = AppLayout.controlHeight)) { content() }
        error?.let { Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodyMedium) }
    }
}

@Composable
fun AppChoiceRow(title: String, selected: Boolean, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Row(
        modifier.fillMaxWidth()
            .background(if (selected) MaterialTheme.colorScheme.secondaryContainer else androidx.compose.ui.graphics.Color.Transparent, RoundedCornerShape(AppLayout.smallRadius))
            .selectable(selected = selected, role = Role.RadioButton, onClick = onClick)
            .padding(horizontal = AppLayout.mediumGap, vertical = AppLayout.gap).heightIn(min = AppLayout.compactRowHeight),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(AppLayout.mediumGap)
    ) {
        RadioButton(selected = selected, onClick = null)
        Text(title, style = MaterialTheme.typography.bodyLarge)
    }
}

@Composable
fun AppHeader(title: String, modifier: Modifier = Modifier, location: String = "", tablet: Boolean = false) {
    val viewModel = AppHeaderViewModel(tablet)
    Column(modifier.fillMaxWidth().background(MaterialTheme.colorScheme.background).padding(horizontal = viewModel.horizontalPadding, vertical = viewModel.verticalPadding)) {
        Row(Modifier.fillMaxWidth().heightIn(min = viewModel.height), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(AppLayout.padding)) {
            Icon(painterResource(R.drawable.ditto_symbol), "Ditto", Modifier.size(viewModel.symbolWidth, viewModel.symbolHeight))
            if (viewModel.expanded) Text(title, style = AppTypography.pageTitle)
            if (location.isNotEmpty()) {
                Row(Modifier.weight(1f), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(AppLayout.locationGap, Alignment.End)) {
                    AppIcon(R.drawable.phosphor_map_pin, size = AppLayout.secondaryIconSize)
                    Text(location, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
        if (!viewModel.expanded) {
            Box(Modifier.heightIn(min = AppLayout.pageTitleHeight), contentAlignment = Alignment.CenterStart) { Text(title, style = AppTypography.pageTitle) }
        }
    }
}

@Composable
fun AppEmptyState(title: String, message: String, @DrawableRes icon: Int, modifier: Modifier = Modifier) {
    Box(modifier.fillMaxSize().padding(AppLayout.sectionGap), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(AppLayout.mediumGap)) {
            AppIcon(icon, size = AppLayout.emptyIconSize)
            Text(title, style = MaterialTheme.typography.titleMedium, textAlign = TextAlign.Center)
            Text(message, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center)
        }
    }
}

@Composable
fun AppWell(modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Surface(
        modifier.heightIn(min = AppLayout.wellHeight),
        shape = RoundedCornerShape(AppLayout.radius),
        color = MaterialTheme.colorScheme.surfaceContainerLow,
        border = BorderStroke(AppLayout.borderWidth, MaterialTheme.colorScheme.outlineVariant),
        content = content
    )
}
