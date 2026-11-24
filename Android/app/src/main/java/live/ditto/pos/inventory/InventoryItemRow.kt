package live.ditto.pos.inventory

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import kotlinx.coroutines.launch
import live.ditto.ui.AppCounter
import live.ditto.ui.AppLayout
import live.ditto.ui.AppSurface
import live.ditto.ui.AppTypography

@Composable
internal fun InventoryItemRow(viewModel: InventoryRowViewModel, inventory: InventoryModel, modifier: Modifier = Modifier, photo: @Composable () -> Unit) {
    val scope = rememberCoroutineScope()
    Column(modifier, verticalArrangement = Arrangement.spacedBy(AppLayout.gap)) {
        AppSurface(contentPadding = PaddingValues(horizontal = AppLayout.gap, vertical = AppLayout.mediumGap)) {
            BoxWithConstraints {
                val controls: @Composable () -> Unit = {
                    AppCounter(
                        canDecrement = viewModel.canDecrement,
                        canIncrement = viewModel.canIncrement,
                        decrement = { scope.launch { inventory.step(-1, viewModel.id) } },
                        increment = { scope.launch { inventory.step(1, viewModel.id) } }
                    ) { QuantityControl(viewModel, inventory) }
                }
                if (viewModel.stacksControls(maxWidth.value)) {
                    Column(verticalArrangement = Arrangement.spacedBy(AppLayout.mediumGap)) {
                        InventoryDetails(viewModel, photo)
                        Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.CenterEnd) { controls() }
                    }
                } else {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(AppLayout.gap)) {
                        Box(Modifier.weight(1f)) { InventoryDetails(viewModel, photo) }
                        controls()
                    }
                }
            }
        }
        viewModel.edit?.error?.let { Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall) }
    }
}

@Composable
private fun InventoryDetails(viewModel: InventoryRowViewModel, photo: @Composable () -> Unit) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(AppLayout.gap)) {
        Box(Modifier.size(AppLayout.thumbnailSize)) { photo() }
        Column(verticalArrangement = Arrangement.spacedBy(AppLayout.smallGap)) {
            Text(viewModel.name, style = MaterialTheme.typography.bodyLarge)
            Text(viewModel.price, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
private fun QuantityControl(row: InventoryRowViewModel, inventory: InventoryModel) {
    val edit = row.edit
    val text = row.text
    val color = row.textColor
    val border = row.borderColor
    val width = row.quantityWidth
    val modifier = Modifier.width(width).heightIn(min = AppLayout.controlHeight).testTag("quantity-${row.id.id}").semantics { contentDescription = "${row.name} quantity" }
    if (edit == null) {
        Surface({ inventory.beginEditing(row.id) }, modifier, enabled = row.canEdit, shape = RoundedCornerShape(AppLayout.buttonRadius), color = MaterialTheme.colorScheme.surface, border = BorderStroke(row.borderWidth, border)) {
            Box(contentAlignment = Alignment.Center) { Text(text, style = AppTypography.quantity, color = color, textAlign = TextAlign.Center, maxLines = 1, overflow = TextOverflow.Ellipsis) }
        }
    } else {
        val scope = rememberCoroutineScope()
        val focusRequester = remember { FocusRequester() }
        var hadFocus by remember { mutableStateOf(false) }
        Surface(modifier, shape = RoundedCornerShape(AppLayout.buttonRadius), color = MaterialTheme.colorScheme.surface, border = BorderStroke(row.borderWidth, border)) {
            Box(contentAlignment = Alignment.Center) {
                BasicTextField(
                    text,
                    inventory::updateText,
                    Modifier.fillMaxWidth().focusRequester(focusRequester)
                        .onFocusChanged {
                            if (it.isFocused) {
                                hadFocus = true
                            } else if (hadFocus && inventory.state.value.edit?.id == row.id) {
                                inventory.cancelEditing()
                            }
                        }
                        .onPreviewKeyEvent {
                            if (it.key == Key.Escape) {
                                inventory.cancelEditing()
                                true
                            } else {
                                false
                            }
                        },
                    textStyle = AppTypography.quantity.copy(color = color, textAlign = TextAlign.Center),
                    singleLine = true,
                    cursorBrush = SolidColor(MaterialTheme.colorScheme.primary),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number, imeAction = ImeAction.Done),
                    keyboardActions = KeyboardActions(onDone = { scope.launch { inventory.submit() } })
                )
            }
        }
        LaunchedEffect(row.id) { focusRequester.requestFocus() }
    }
}
