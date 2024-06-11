package live.ditto.pos.core.presentation.viewmodel

import androidx.lifecycle.ViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import live.ditto.Ditto
import live.ditto.pos.core.domain.usecase.IsSetupValidUseCase
import live.ditto.pos.core.domain.usecase.ditto.GetDittoInstanceUseCase
import live.ditto.pos.core.domain.usecase.ditto.RefreshDittoPermissionsUseCase
import javax.inject.Inject

@HiltViewModel
class PosKdsViewModel @Inject constructor(
    private val refreshDittoPermissionsUseCase: RefreshDittoPermissionsUseCase,
    private val getDittoInstanceUseCase: GetDittoInstanceUseCase,
    private val isSetupValidUseCase: IsSetupValidUseCase
) : ViewModel() {
    fun refreshDittoPermissions() {
        refreshDittoPermissionsUseCase()
    }

    fun requireDitto(): Ditto {
        return getDittoInstanceUseCase()
    }

    suspend fun isLocationConfigured(): Boolean {
        return isSetupValidUseCase()
    }
}
