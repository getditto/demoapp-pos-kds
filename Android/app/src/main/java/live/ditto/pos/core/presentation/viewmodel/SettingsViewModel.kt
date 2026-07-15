package live.ditto.pos.core.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import live.ditto.pos.core.data.locations.Location
import live.ditto.pos.core.domain.usecase.GetCurrentLocationUseCase
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val currentLocationUseCase: GetCurrentLocationUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(
        SettingsState(
            currentLocation = null
        )
    )
    val uiState = _uiState.asStateFlow()

    init {
        viewModelScope.launch(Dispatchers.IO) {
            updateUiState()
        }
    }

    private suspend fun updateUiState() {
        val currentLocation = currentLocationUseCase()
        _uiState.update {
            it.copy(
                currentLocation = currentLocation
            )
        }
    }
}

data class SettingsState(
    val currentLocation: Location?
)
