package live.ditto.pos.core.presentation.viewmodel

import androidx.lifecycle.ViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import live.ditto.Ditto
import live.ditto.ditto_wrapper.DittoManager
import javax.inject.Inject

@HiltViewModel
class PosKdsViewModel @Inject constructor(
    private val dittoManager: DittoManager
) : ViewModel() {
    fun requireDitto(): Ditto = dittoManager.requireDitto()
}
