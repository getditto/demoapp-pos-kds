package live.ditto.pos.core.data.demo

// Demo-only data.

import live.ditto.pos.core.data.DocumentID
import live.ditto.pos.core.data.Price
import live.ditto.pos.core.data.SaleItem

object SaleItemSeed {
    const val INITIAL_QUANTITY = 20L

    private data class Item(
        val id: String,
        val name: String,
        val cents: Int
    )

    private val catalog: List<Item> = listOf(
        Item("00001", "Burger", 850),
        Item("00002", "Burrito", 650),
        Item("00003", "Fried Chicken", 800),
        Item("00004", "Potato Chips", 250),
        Item("00005", "Coffee", 195),
        Item("00006", "Cookies", 350),
        Item("00007", "Corn", 350),
        Item("00008", "French Fries", 350),
        Item("00009", "Fruit Salad", 650),
        Item("00010", "Gumbo", 995),
        Item("00011", "Ice Cream", 250),
        Item("00012", "Milk", 200),
        Item("00013", "Onion Rings", 350),
        Item("00014", "Pancakes", 550),
        Item("00015", "Pie", 450),
        Item("00016", "Salad", 650),
        Item("00017", "Sandwich", 450),
        Item("00018", "Soft Drink", 150),
        Item("00019", "Tacos", 650),
        Item("00020", "Veggie Plate", 750)
    )

    private val menus: Map<String, List<String>> = mapOf(
        "00001" to listOf("00001", "00008", "00013", "00018", "00012", "00011", "00006"),
        "00002" to listOf("00016", "00009", "00020", "00017", "00018", "00005", "00012"),
        "00003" to listOf("00003", "00017", "00016", "00020", "00018", "00005", "00006"),
        "00004" to listOf("00017", "00016", "00020", "00009", "00018", "00005", "00015"),
        "00005" to listOf("00014", "00009", "00005", "00012", "00011", "00015", "00006"),
        "00006" to listOf("00010", "00017", "00007", "00018", "00012", "00015"),
        "00007" to listOf("00019", "00002", "00007", "00018", "00003", "00011")
    )

    fun saleItemsForAllLocations(): List<SaleItem> {
        val byId = catalog.associateBy { it.id }
        return LocationSeed.demoLocations.flatMap { location ->
            menus.getValue(location.id).map { itemId ->
                val item = byId.getValue(itemId)
                SaleItem(DocumentID(item.id, location.id), item.name, Price(item.cents), quantity = INITIAL_QUANTITY)
            }
        }
    }
}
