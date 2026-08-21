package live.ditto.pos.core.domain.usecase

import kotlinx.coroutines.flow.Flow
import live.ditto.pos.core.data.locations.Location
import live.ditto.pos.core.data.repository.LocationsRepository
import javax.inject.Inject

/**
 * The active location, resolved against the synced `locations` collection and
 * emitted on every change. Mirrors iOS `LocationsRepository.currentLocation`.
 */
class GetCurrentLocationUseCase @Inject constructor(
    private val locationsRepository: LocationsRepository
) {

    operator fun invoke(): Flow<Location?> = locationsRepository.currentLocationFlow()
}
