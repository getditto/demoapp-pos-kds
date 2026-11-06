// Frozen beab457 legacy seeding; wire payload and INITIAL statements retained.
package live.ditto.pos.legacy

// Demo-only data.

import live.ditto.pos.core.data.locations.Location

object LegacyLocationSeed {
    val demoLocations: List<Location> = listOf(
        Location(id = "00001", name = "Ham's Burgers"),
        Location(id = "00002", name = "Sally's Salad Bar"),
        Location(id = "00003", name = "Kyle's Kabobs"),
        Location(id = "00004", name = "Frank's Falafels"),
        Location(id = "00005", name = "Cathy's Crepes"),
        Location(id = "00006", name = "Gilbert's Gumbo"),
        Location(id = "00007", name = "Tarra's Tacos")
    )

    val demoLocationIds: List<String> get() = demoLocations.map { it.id }
}
