package live.ditto.pos.core.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.ditto.kotlin.Ditto
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.stateIn
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

    val configuration = appConfigurationStateUseCase().stateIn(
        viewModelScope,
        SharingStarted.Eagerly,
        AppConfigurationState.LOCATION_NEEDED
    )

    val uiState = combine(
        getCurrentLocationUseCase(),
        locationsRepository.observeAllLocations()
    ) { location, locations ->
        AppState(location?.name.orEmpty(), locations.orEmpty(), isLoading = locations == null)
    }.flowOn(Dispatchers.IO).stateIn(
        viewModelScope,
        SharingStarted.WhileSubscribed(stopTimeoutMillis = 0, replayExpirationMillis = 0),
        AppState("", emptyList(), isLoading = true)
    )

    fun checkDittoPermissions(onPermissionsChecked: (missingPermissions: Array<String>) -> Unit) {
        onPermissionsChecked(getMissingPermissionsUseCase())
    }

    fun refreshDittoPermissions() {
        refreshDittoPermissionsUseCase()
    }

    fun requireDitto(): Ditto = getDittoInstanceUseCase()

    fun updateCurrentLocation(locationId: String) {
        viewModelScope.launch(Dispatchers.IO) {
            locationsRepository.setActiveLocation(locationId = locationId)
        }
    }
}

data class AppState(
    val currentLocationName: String,
    val locations: List<Location>,
    val isLoading: Boolean = false
)
