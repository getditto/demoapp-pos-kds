package live.ditto.pos.core.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import live.ditto.Ditto
import live.ditto.pos.core.domain.usecase.GetCurrentLocationUseCase
import live.ditto.pos.core.domain.usecase.IsSetupValidUseCase
import live.ditto.pos.core.domain.usecase.IsUsingDemoLocationsUseCase
import live.ditto.pos.core.domain.usecase.SetCurrentLocationUseCase
import live.ditto.pos.core.domain.usecase.UseDemoLocationUseCase
import live.ditto.pos.core.domain.usecase.ditto.GetDittoInstanceUseCase
import live.ditto.pos.core.domain.usecase.ditto.GetMissingPermissionsUseCase
import live.ditto.pos.core.domain.usecase.ditto.RefreshDittoPermissionsUseCase
import javax.inject.Inject

@HiltViewModel
class CoreViewModel @Inject constructor(
    private val refreshDittoPermissionsUseCase: RefreshDittoPermissionsUseCase,
    private val getDittoInstanceUseCase: GetDittoInstanceUseCase,
    private val isSetupValidUseCase: IsSetupValidUseCase,
    private val getCurrentLocationUseCase: GetCurrentLocationUseCase,
    private val getMissingPermissionsUseCase: GetMissingPermissionsUseCase,
    private val setCurrentLocationUseCase: SetCurrentLocationUseCase,
    private val useDemoLocationUseCase: UseDemoLocationUseCase,
    private val isUsingDemoLocationsUseCase: IsUsingDemoLocationsUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(
        AppState(
            currentLocationName = "",
            isSetupValid = false,
            isDemoLocationsMode = false
        )
    )
    val uiState = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            validateSetup(getCurrentLocationUseCase()?.id)
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
        viewModelScope.launch {
            validateSetup(locationId = locationId)
        }
    }

    fun shouldUseDemoLocations(shouldUseDemoLocations: Boolean) {
        viewModelScope.launch {
            useDemoLocationUseCase(shouldUseDemoLocations)
            updateIsUsingDemoLocations(isUsingDemoLocations = shouldUseDemoLocations)
        }
    }

    private suspend fun validateSetup(locationId: String? = null) {
        locationId?.let {
            setCurrentLocationUseCase(locationId = locationId)
        }
        val isSetupValid = isSetupValidUseCase()
        val isUsingDemoLocations = isUsingDemoLocationsUseCase()
        updateSetupState(setupValid = isSetupValid)
        updateLocationName()
        updateIsUsingDemoLocations(isUsingDemoLocations = isUsingDemoLocations)
    }

    private fun updateIsUsingDemoLocations(isUsingDemoLocations: Boolean) {
        _uiState.value = _uiState.value.copy(
            isDemoLocationsMode = isUsingDemoLocations
        )
    }

    private suspend fun updateLocationName() {
        val locationName = getCurrentLocationUseCase()?.name ?: ""
        _uiState.value = _uiState.value.copy(
            currentLocationName = locationName
        )
    }

    private fun updateSetupState(setupValid: Boolean) {
        _uiState.value = _uiState.value.copy(
            isSetupValid = setupValid
        )
    }
}

data class AppState(
    val currentLocationName: String,
    val isSetupValid: Boolean,
    val isDemoLocationsMode: Boolean
)
