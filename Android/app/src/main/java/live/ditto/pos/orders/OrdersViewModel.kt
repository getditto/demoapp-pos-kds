package live.ditto.pos.orders

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import live.ditto.pos.core.data.orders.OrdersHistory
import live.ditto.pos.core.data.repository.OrdersRepository
import live.ditto.pos.settings.AppSettings
import javax.inject.Inject

@HiltViewModel
class OrdersViewModel @Inject constructor(settings: AppSettings, repository: OrdersRepository) : ViewModel() {
    val history = OrdersHistory(viewModelScope, repository::observeHistoryPage, repository::observeHistoryCount)
    init {
        viewModelScope.launch { settings.locationIdFlow().collect { history.setLocation(it.takeIf(String::isNotEmpty)) } }
    }
}
