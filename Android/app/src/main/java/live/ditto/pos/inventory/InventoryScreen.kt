package live.ditto.pos.inventory

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.isImeVisible
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.relocation.BringIntoViewRequester
import androidx.compose.foundation.relocation.bringIntoViewRequester
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
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
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.launch
import live.ditto.pos.core.data.SaleItem
import live.ditto.pos.core.presentation.images.ProductPhoto
import live.ditto.ui.AppCatalogRow
import live.ditto.ui.AppCounter
import live.ditto.ui.AppEmptyState
import live.ditto.ui.AppEmptyStateStyle
import live.ditto.ui.AppLayout
import live.ditto.ui.AppTextButton
import live.ditto.ui.AppTypography
import live.ditto.ui.R

@Composable
fun InventoryScreen(viewModel: InventoryViewModel = hiltViewModel()) {
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    DisposableEffect(viewModel, lifecycle) {
        val observer = LifecycleEventObserver { _, _ -> viewModel.inventory.setVisible(lifecycle.currentState.isAtLeast(Lifecycle.State.RESUMED)) }
        lifecycle.addObserver(observer)
        viewModel.inventory.setVisible(lifecycle.currentState.isAtLeast(Lifecycle.State.RESUMED))
        onDispose {
            lifecycle.removeObserver(observer)
            viewModel.inventory.setVisible(false)
        }
    }
    InventoryContent(viewModel.inventory) { item ->
        ProductPhoto(item.image, item.documentId, viewModel.repository.photoStore, Modifier.fillMaxSize())
    }
}

@OptIn(androidx.compose.foundation.layout.ExperimentalLayoutApi::class)
@Composable
fun InventoryContent(inventory: InventoryModel, modifier: Modifier = Modifier, photo: @Composable (SaleItem) -> Unit) {
    val state by inventory.state.collectAsStateWithLifecycle()
    val scope = rememberCoroutineScope()
    val focus = LocalFocusManager.current
    val keyboard = LocalSoftwareKeyboardController.current
    val imeVisible = WindowInsets.isImeVisible
    var sawKeyboard by remember(state.edit?.id) { mutableStateOf(false) }
    LaunchedEffect(imeVisible, state.edit?.id) {
        if (imeVisible) {
            sawKeyboard = true
        } else if (sawKeyboard) {
            inventory.cancelEditing()
        }
    }
    LaunchedEffect(state.edit?.id) {
        if (state.edit == null) {
            focus.clearFocus()
            keyboard?.hide()
        }
    }
    BackHandler(state.edit != null) { inventory.cancelEditing() }
    Column(modifier.fillMaxSize().imePadding()) {
        when {
            state.isLoading -> Box(Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
            state.items.isEmpty() -> AppEmptyState("No items yet", "Items for this location will appear here.", R.drawable.phosphor_package, Modifier.weight(1f), AppEmptyStateStyle.LARGE)
            else -> LazyColumn(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(12.dp), contentPadding = androidx.compose.foundation.layout.PaddingValues(AppLayout.padding)) {
                if (state.edit == null) item { Text("${state.items.size} items", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant) }
                items(state.items, key = { it.documentId.id }) { item ->
                    val edit = state.edit?.takeIf { it.id == item.documentId }
                    val requester = remember { BringIntoViewRequester() }
                    LaunchedEffect(imeVisible, edit?.id) { if (imeVisible && edit != null) requester.bringIntoView() }
                    Column(Modifier.bringIntoViewRequester(requester), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        AppCatalogRow(item.name, item.price.formatted(), photo = { photo(item) }, controls = {
                            AppCounter(
                                canDecrement = item.quantity > 0 && edit == null,
                                canIncrement = edit == null,
                                decrement = { scope.launch { inventory.step(-1, item.documentId) } },
                                increment = { scope.launch { inventory.step(1, item.documentId) } }
                            ) {
                                QuantityControl(item, edit, state.edit == null, inventory)
                            }
                        })
                        edit?.error?.let { Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall) }
                    }
                }
            }
        }
        if (state.edit != null) {
            Surface(color = MaterialTheme.colorScheme.surface) {
                Row(Modifier.fillMaxWidth().padding(horizontal = AppLayout.padding)) {
                    Spacer(Modifier.weight(1f))
                    AppTextButton("DONE", { scope.launch { inventory.submit() } }, Modifier.testTag("quantity-done"), enabled = state.edit?.value != null)
                }
            }
        }
    }
}

@Composable
private fun QuantityControl(item: SaleItem, edit: QuantityEdit?, canEdit: Boolean, inventory: InventoryModel) {
    val text = edit?.text ?: item.quantity.toString()
    val invalid = if (edit != null) edit.error != null else item.quantity < 0
    val color = if (invalid) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurface
    val border = if (invalid) {
        MaterialTheme.colorScheme.error
    } else if (edit != null) {
        MaterialTheme.colorScheme.primary
    } else {
        MaterialTheme.colorScheme.outlineVariant
    }
    val width = (text.length * 11 * LocalDensity.current.fontScale + 16).coerceIn(48f, 144f).dp
    val modifier = Modifier.size(width, AppLayout.controlHeight).testTag("quantity-${item.documentId.id}").semantics { contentDescription = "${item.name} quantity" }
    if (edit == null) {
        Surface({ inventory.beginEditing(item.documentId) }, modifier, enabled = canEdit, shape = RoundedCornerShape(12.dp), color = MaterialTheme.colorScheme.surface, border = BorderStroke(1.dp, border)) {
            Box(contentAlignment = Alignment.Center) { Text(text, style = AppTypography.quantity, color = color, textAlign = TextAlign.Center) }
        }
    } else {
        val scope = rememberCoroutineScope()
        val focusRequester = remember { FocusRequester() }
        var hadFocus by remember { mutableStateOf(false) }
        Surface(modifier, shape = RoundedCornerShape(12.dp), color = MaterialTheme.colorScheme.surface, border = BorderStroke(2.dp, border)) {
            Box(contentAlignment = Alignment.Center) {
                BasicTextField(
                    text,
                    inventory::updateText,
                    Modifier.fillMaxWidth().focusRequester(focusRequester)
                        .onFocusChanged {
                            if (it.isFocused) {
                                hadFocus = true
                            } else if (hadFocus && inventory.state.value.edit?.id == item.documentId) {
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
        LaunchedEffect(item.documentId) { focusRequester.requestFocus() }
    }
}
