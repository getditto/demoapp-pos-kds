package live.ditto.pos.core.data.demo

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class SaleItemSeedTest {

    @Test
    fun `every demo location has at least one menu item`() {
        val items = SaleItemSeed.saleItemsForAllLocations()
        for (location in LocationSeed.demoLocations) {
            val perLocation = items.filter { it.documentId.locationId == location.id }
            assertTrue(
                "Location ${location.id} (${location.name}) has no menu items",
                perLocation.isNotEmpty()
            )
        }
    }

    @Test
    fun `composite ids are unique across all seeded items`() {
        val items = SaleItemSeed.saleItemsForAllLocations()
        val keys = items.map { it.documentId.id to it.documentId.locationId }
        assertEquals(
            "Duplicate (id, locationId) pairs detected in seed data",
            keys.size,
            keys.toSet().size
        )
    }

    @Test
    fun `every seeded item has a positive price`() {
        val items = SaleItemSeed.saleItemsForAllLocations()
        for (item in items) {
            assertTrue(
                "Item ${item.name} (${item.documentId.id}) at ${item.documentId.locationId} has non-positive cents",
                item.price.amount > 0
            )
        }
    }
}
