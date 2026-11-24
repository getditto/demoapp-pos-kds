package live.ditto.pos.inventory

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import live.ditto.pos.core.data.repository.SaleItemsRepository
import live.ditto.pos.settings.AppSettings
import javax.inject.Inject

@HiltViewModel
class InventoryViewModel @Inject constructor(settings: AppSettings, val repository: SaleItemsRepository) : ViewModel() {
    val inventory = InventoryModel(viewModelScope, repository::observeLocationSaleItems, repository::increment, repository::restart)
    init {
        viewModelScope.launch { settings.locationIdFlow().collect { inventory.setLocation(it.takeIf(String::isNotEmpty)) } }
    }
}
