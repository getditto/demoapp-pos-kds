package live.ditto.pos.core.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.update
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
        currentLocationUseCase()
            .onEach { currentLocation ->
                _uiState.update {
                    it.copy(
                        currentLocation = currentLocation
                    )
                }
            }
            .flowOn(Dispatchers.IO)
            .launchIn(viewModelScope)
    }
}

data class SettingsState(
    val currentLocation: Location?
)
