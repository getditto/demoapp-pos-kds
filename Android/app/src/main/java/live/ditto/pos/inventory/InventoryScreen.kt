package live.ditto.pos.inventory

import androidx.activity.compose.BackHandler
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.relocation.BringIntoViewRequester
import androidx.compose.foundation.relocation.bringIntoViewRequester
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
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.platform.testTag
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.launch
import live.ditto.pos.core.data.SaleItem
import live.ditto.pos.core.presentation.images.ProductPhoto
import live.ditto.ui.AppEmptyState
import live.ditto.ui.AppEmptyStateStyle
import live.ditto.ui.AppLayout
import live.ditto.ui.AppTextButton
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
    val fontScale = LocalDensity.current.fontScale
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
            else -> LazyColumn(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(AppLayout.mediumGap), contentPadding = androidx.compose.foundation.layout.PaddingValues(AppLayout.padding)) {
                if (state.edit == null) item { Text("${state.items.size} items", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant) }
                items(state.items, key = { it.documentId.id }) { item ->
                    val row = InventoryRowViewModel(item, state.edit, fontScale)
                    val edit = row.edit
                    val requester = remember { BringIntoViewRequester() }
                    LaunchedEffect(imeVisible, edit?.id) { if (imeVisible && edit != null) requester.bringIntoView() }
                    InventoryItemRow(row, inventory, Modifier.bringIntoViewRequester(requester)) { photo(item) }
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
