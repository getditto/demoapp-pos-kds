package live.ditto.pos.core.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ditto.kotlin.Ditto
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import live.ditto.pos.core.data.locations.Location
import live.ditto.pos.core.data.repository.LocationsRepository
import live.ditto.pos.core.domain.usecase.AppConfigurationStateUseCase
import live.ditto.pos.core.domain.usecase.AppConfigurationStateUseCase.AppConfigurationState
import live.ditto.pos.core.domain.usecase.GetCurrentLocationUseCase
import live.ditto.pos.core.domain.usecase.ditto.GetDittoInstanceUseCase
import live.ditto.pos.core.domain.usecase.ditto.GetMissingPermissionsUseCase
import live.ditto.pos.core.domain.usecase.ditto.RefreshDittoPermissionsUseCase
import javax.inject.Inject

@HiltViewModel
class MainViewModel @Inject constructor(
    private val refreshDittoPermissionsUseCase: RefreshDittoPermissionsUseCase,
    private val getDittoInstanceUseCase: GetDittoInstanceUseCase,
    private val appConfigurationStateUseCase: AppConfigurationStateUseCase,
    private val getCurrentLocationUseCase: GetCurrentLocationUseCase,
    private val getMissingPermissionsUseCase: GetMissingPermissionsUseCase,
    private val locationsRepository: LocationsRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(
        AppState(
            currentLocationName = "",
            locations = emptyList(),
            appConfigurationState = AppConfigurationState.LOCATION_NEEDED
        )
    )
    val uiState = _uiState.asStateFlow()

    init {
        // Every field below derives from the active location, so picking one
        // drives the setup gate, the title, and the picker with no imperative
        // refresh. Mirrors iOS, where all three hang off `$currentLocationId`.
        appConfigurationStateUseCase()
            .onEach { appConfigurationState ->
                _uiState.update { currentState ->
                    currentState.copy(
                        appConfigurationState = appConfigurationState
                    )
                }
            }
            .flowOn(Dispatchers.IO)
            .launchIn(viewModelScope)

        // Title follows the active location, live — a rename synced from
        // another peer lands here without a re-pull. Mirrors iOS `mainTitle`.
        getCurrentLocationUseCase()
            .onEach { location ->
                _uiState.update { currentState ->
                    currentState.copy(
                        currentLocationName = location?.name ?: ""
                    )
                }
            }
            .flowOn(Dispatchers.IO)
            .launchIn(viewModelScope)

        // Backs the location picker. Both picker screens read this rather than
        // the demo seed, so what's on screen is what's in the collection.
        locationsRepository.observeAllLocations()
            .onEach { locations ->
                _uiState.update { currentState ->
                    currentState.copy(
                        locations = locations
                    )
                }
            }
            .flowOn(Dispatchers.IO)
            .launchIn(viewModelScope)
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

    /**
     * The only writer. Persisting the id is what advances the gate, the title,
     * and the picker — they all observe it.
     */
    fun updateCurrentLocation(locationId: String) {
        viewModelScope.launch(Dispatchers.IO) {
            locationsRepository.setActiveLocation(locationId = locationId)
        }
    }
}

data class AppState(
    val currentLocationName: String,
    val locations: List<Location>,
    val appConfigurationState: AppConfigurationState
)
