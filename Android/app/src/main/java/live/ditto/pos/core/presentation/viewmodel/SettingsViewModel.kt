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
import live.ditto.pos.core.domain.usecase.IsUsingDemoLocationsUseCase
import live.ditto.pos.core.domain.usecase.UseDemoLocationUseCase
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val useDemoLocationUseCase: UseDemoLocationUseCase,
    private val isUsingDemoLocationUseCase: IsUsingDemoLocationsUseCase,
    private val currentLocationUseCase: GetCurrentLocationUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(
        SettingsState(
            isUsingDemoLocations = false,
            currentLocation = null
        )
    )
    val uiState = _uiState.asStateFlow()

    init {
        viewModelScope.launch(Dispatchers.IO) {
            updateUiState()
        }
    }

    fun shouldUseDemoLocations(shouldUseDemoLocations: Boolean) {
        viewModelScope.launch(Dispatchers.IO) {
            useDemoLocationUseCase(shouldUseDemoLocations)
            updateUiState()
        }
    }

    private suspend fun updateUiState() {
        val isUsingDemoLocations = isUsingDemoLocationUseCase()
        val currentLocation = currentLocationUseCase()
        _uiState.update {
            it.copy(
                isUsingDemoLocations = isUsingDemoLocations,
                currentLocation = currentLocation
            )
        }
    }
}

data class SettingsState(
    val isUsingDemoLocations: Boolean,
    val currentLocation: Location?
)
