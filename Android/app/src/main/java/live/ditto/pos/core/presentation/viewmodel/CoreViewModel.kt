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
import live.ditto.pos.core.domain.usecase.IsUsingDemoLocationsUseCase
import live.ditto.pos.core.domain.usecase.SetCurrentLocationUseCase
import live.ditto.pos.core.domain.usecase.UpdateCustomLocationUseCase
import live.ditto.pos.core.domain.usecase.UseDemoLocationUseCase
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
    private val setCurrentLocationUseCase: SetCurrentLocationUseCase,
    private val useDemoLocationUseCase: UseDemoLocationUseCase,
    private val isUsingDemoLocationsUseCase: IsUsingDemoLocationsUseCase,
    private val updateCustomLocationUseCase: UpdateCustomLocationUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(
        AppState(
            currentLocationName = "",
            appConfigurationState = AppConfigurationState.DEMO_OR_CUSTOM_LOCATION_NEEDED,
            isDemoLocationsMode = false
        )
    )
    val uiState = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
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

    fun shouldUseDemoLocations(shouldUseDemoLocations: Boolean) {
        viewModelScope.launch(Dispatchers.IO) {
            useDemoLocationUseCase(shouldUseDemoLocations)
            updateIsUsingDemoLocations(isUsingDemoLocations = shouldUseDemoLocations)
        }
    }

    fun updateCustomLocation(companyName: String, locationName: String) {
        viewModelScope.launch(Dispatchers.IO) {
            updateCustomLocationUseCase(
                companyName = companyName,
                locationName = locationName
            )
            updateAppState()
        }
    }

    suspend fun updateAppState() {
        val isSetupValid = appConfigurationStateUseCase()
        val isUsingDemoLocations = isUsingDemoLocationsUseCase()
        updateAppConfigurationState(appConfigurationState = isSetupValid)
        updateLocationName()
        updateIsUsingDemoLocations(isUsingDemoLocations = isUsingDemoLocations)
    }

    private fun updateIsUsingDemoLocations(isUsingDemoLocations: Boolean) {
        _uiState.update { currentState ->
            currentState.copy(
                isDemoLocationsMode = isUsingDemoLocations
            )
        }
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
    val appConfigurationState: AppConfigurationState,
    val isDemoLocationsMode: Boolean
)
