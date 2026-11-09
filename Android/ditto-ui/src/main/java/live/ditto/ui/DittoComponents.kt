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
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

@Composable
fun DittoIcon(@DrawableRes icon: Int, modifier: Modifier = Modifier, description: String? = null, size: Dp = 24.dp) {
    Icon(painterResource(icon), contentDescription = description, modifier = modifier.size(size))
}

@Composable
fun DittoButton(text: String, onClick: () -> Unit, modifier: Modifier = Modifier, enabled: Boolean = true, secondary: Boolean = false) {
    if (secondary) {
        OutlinedButton(
            onClick,
            modifier.heightIn(min = DittoLayout.controlHeight),
            enabled = enabled,
            shape = RoundedCornerShape(DittoLayout.radius),
            colors = ButtonDefaults.outlinedButtonColors(contentColor = MaterialTheme.colorScheme.onSurface),
            border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant)
        ) { Text(text, style = DittoTypography.action) }
    } else {
        Button(
            onClick,
            modifier.heightIn(min = DittoLayout.controlHeight),
            enabled = enabled,
            shape = RoundedCornerShape(DittoLayout.radius),
            colors = ButtonDefaults.buttonColors(containerColor = DittoColors.actionFill, contentColor = DittoColors.onAction)
        ) { Text(text, style = DittoTypography.action) }
    }
}

@Composable
fun DittoSurface(modifier: Modifier = Modifier, content: @Composable ColumnScope.() -> Unit) {
    Surface(modifier, shape = RoundedCornerShape(DittoLayout.radius), color = MaterialTheme.colorScheme.surface) {
        Column(Modifier.padding(DittoLayout.padding), content = content)
    }
}

@Composable
fun DittoRow(title: String, @DrawableRes icon: Int, onClick: () -> Unit, modifier: Modifier = Modifier, detail: String? = null, trailing: @Composable RowScope.() -> Unit = { DittoIcon(R.drawable.phosphor_caret_right) }) {
    Surface(onClick, modifier.fillMaxWidth(), shape = RoundedCornerShape(DittoLayout.radius), color = MaterialTheme.colorScheme.surface) {
        Row(Modifier.padding(DittoLayout.padding).heightIn(min = DittoLayout.controlHeight), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            DittoIcon(icon)
            Column(Modifier.weight(1f)) {
                Text(title, style = MaterialTheme.typography.bodyLarge)
                detail?.let { Text(it, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant) }
            }
            trailing()
        }
    }
}

@Composable
fun DittoField(label: String, modifier: Modifier = Modifier, error: String? = null, content: @Composable () -> Unit) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(DittoLayout.gap)) {
        Text(label, style = MaterialTheme.typography.bodyMedium)
        Box(Modifier.fillMaxWidth().border(1.dp, if (error == null) MaterialTheme.colorScheme.outlineVariant else MaterialTheme.colorScheme.error, RoundedCornerShape(12.dp)).background(MaterialTheme.colorScheme.surface, RoundedCornerShape(12.dp)).padding(12.dp).heightIn(min = DittoLayout.controlHeight)) { content() }
        error?.let { Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodyMedium) }
    }
}

@Composable
fun DittoHeader(title: String, modifier: Modifier = Modifier, location: String = "", tablet: Boolean = false) {
    Column(modifier.fillMaxWidth().padding(horizontal = if (tablet) 24.dp else DittoLayout.padding, vertical = DittoLayout.padding), verticalArrangement = Arrangement.spacedBy(20.dp)) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Icon(painterResource(R.drawable.ditto_symbol), "Ditto", Modifier.size(if (tablet) 28.dp else 24.5.dp, if (tablet) 32.dp else 28.dp))
            Spacer(Modifier.weight(1f))
            if (location.isNotEmpty()) {
                Row(Modifier.weight(3f, fill = false), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    DittoIcon(R.drawable.phosphor_map_pin, size = 18.dp)
                    Text(location, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
        Text(title, style = DittoTypography.pageTitle)
    }
}

@Composable
fun DittoEmptyState(title: String, message: String, @DrawableRes icon: Int, modifier: Modifier = Modifier) {
    Box(modifier.fillMaxSize().padding(24.dp), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
            DittoIcon(icon, size = 56.dp)
            Text(title, style = MaterialTheme.typography.titleMedium, textAlign = TextAlign.Center)
            Text(message, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center)
        }
    }
}

@Composable
fun DittoWell(modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Surface(
        modifier.heightIn(min = 240.dp),
        shape = RoundedCornerShape(DittoLayout.radius),
        color = MaterialTheme.colorScheme.surfaceContainerLow,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant),
        content = content
    )
}
