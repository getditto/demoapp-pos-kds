package live.ditto.pos.core.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import live.ditto.Ditto
import live.ditto.pos.core.domain.usecase.AppConfigurationStateUseCase
import live.ditto.pos.core.domain.usecase.AppConfigurationStateUseCase.AppConfigurationState
import live.ditto.pos.core.domain.usecase.GetCurrentLocationUseCase
import live.ditto.pos.core.domain.usecase.SetCurrentLocationUseCase
import live.ditto.pos.core.domain.usecase.ditto.GetDittoInstanceUseCase
import live.ditto.pos.core.domain.usecase.ditto.GetMissingPermissionsUseCase
import live.ditto.pos.core.domain.usecase.ditto.RefreshDittoPermissionsUseCase
import javax.inject.Inject

@HiltViewModel
class CoreViewModel @Inject constructor(
    private val refreshDittoPermissionsUseCase: RefreshDittoPermissionsUseCase,
    private val getDittoInstanceUseCase: GetDittoInstanceUseCase,
    private val appConfigurationStateUseCase: AppConfigurationStateUseCase,
    private val getCurrentLocationUseCase: GetCurrentLocationUseCase,
    private val getMissingPermissionsUseCase: GetMissingPermissionsUseCase,
    private val setCurrentLocationUseCase: SetCurrentLocationUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(
        AppState(
            currentLocationName = "",
            appConfigurationState = AppConfigurationState.LOCATION_NEEDED
        )
    )
    val uiState = _uiState.asStateFlow()

    init {
        viewModelScope.launch(Dispatchers.IO) {
            // If a location is already stored, restore routing config and subscriptions
            val state = appConfigurationStateUseCase()
            if (state == AppConfigurationState.VALID) {
                val location = getCurrentLocationUseCase()
                if (location != null) {
                    setCurrentLocationUseCase(locationId = location.id)
                }
            }
            updateAppState()
        }
    }

    fun checkDittoPermissions(onPermissionsChecked: (missingPermissions: Array<String>) -> Unit) {
        onPermissionsChecked(getMissingPermissionsUseCase())
    }

    fun refreshDittoPermissions() {
        refreshDittoPermissionsUseCase()
    }

    fun requireDitto(): Ditto {
        return getDittoInstanceUseCase()
    }

    fun updateCurrentLocation(locationId: String) {
        viewModelScope.launch(Dispatchers.IO) {
            setCurrentLocationUseCase(locationId = locationId)
            updateAppState()
        }
    }

    suspend fun updateAppState() {
        val isSetupValid = appConfigurationStateUseCase()
        updateAppConfigurationState(appConfigurationState = isSetupValid)
        updateLocationName()
    }

    private suspend fun updateLocationName() {
        val locationName = getCurrentLocationUseCase()?.name ?: ""
        _uiState.update { currentState ->
            currentState.copy(
                currentLocationName = locationName
            )
        }
    }

    private fun updateAppConfigurationState(appConfigurationState: AppConfigurationState) {
        _uiState.update { currentState ->
            currentState.copy(
                appConfigurationState = appConfigurationState
            )
        }
    }
}

data class AppState(
    val currentLocationName: String,
    val appConfigurationState: AppConfigurationState
)
