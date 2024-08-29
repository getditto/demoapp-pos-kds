package live.ditto.pos.core.data

import live.ditto.pos.R
import live.ditto.pos.core.data.locations.Location
import live.ditto.pos.core.data.orders.OrderStatus
import live.ditto.pos.kds.TicketItemUi
import live.ditto.pos.pos.presentation.uimodel.OrderItemUiModel
import live.ditto.pos.pos.presentation.uimodel.SaleItemUiModel

val demoMenuData = listOf(
    SaleItemUiModel(
        id = "00001",
        imageResource = R.drawable.burger,
        label = "Burger",
        price = 8.5
    ),
    SaleItemUiModel(
        id = "00002",
        imageResource = R.drawable.burrito,
        label = "Burrito",
        price = 6.5
    ),
    SaleItemUiModel(
        id = "00003",
        imageResource = R.drawable.chicken,
        label = "Fried Chicken",
        price = 8.0
    ),
    SaleItemUiModel(
        id = "00004",
        imageResource = R.drawable.chips,
        label = "Potato Chips",
        price = 2.5
    ),
    SaleItemUiModel(
        id = "00005",
        imageResource = R.drawable.coffee,
        label = "Coffee",
        price = 1.95
    ),
    SaleItemUiModel(
        id = "00006",
        imageResource = R.drawable.cookies,
        label = "Cookies",
        price = 3.5
    ),
    SaleItemUiModel(
        id = "00007",
        imageResource = R.drawable.corn_on_cob,
        label = "Corn",
        price = 3.5
    ),
    SaleItemUiModel(
        id = "00008",
        imageResource = R.drawable.fries,
        label = "French Fries",
        price = 3.5
    ),
    SaleItemUiModel(
        id = "00009",
        imageResource = R.drawable.fruit_salad,
        label = "Fruit Salad",
        price = 6.5
    ),
    SaleItemUiModel(
        id = "00010",
        imageResource = R.drawable.gumbo,
        label = "Gumbo",
        price = 9.95
    ),
    SaleItemUiModel(
        id = "00011",
        imageResource = R.drawable.ice_cream,
        label = "Ice Cream",
        price = 2.5
    ),
    SaleItemUiModel(
        id = "00012",
        imageResource = R.drawable.milk,
        label = "Milk",
        price = 2.0
    ),
    SaleItemUiModel(
        "00013",
        imageResource = R.drawable.onion_rings,
        label = "Onion Rings",
        price = 3.5
    ),
    SaleItemUiModel(
        id = "00014",
        imageResource = R.drawable.pancakes,
        label = "Pancakes",
        price = 5.5
    ),
    SaleItemUiModel(
        id = "00015",
        imageResource = R.drawable.pie,
        label = "Pie",
        price = 4.5
    ),
    SaleItemUiModel(
        id = "00016",
        imageResource = R.drawable.salad,
        label = "Salad",
        price = 6.5
    ),
    SaleItemUiModel(
        id = "00017",
        imageResource = R.drawable.sandwich,
        label = "Sandwich",
        price = 4.5
    ),
    SaleItemUiModel(
        id = "00018",
        imageResource = R.drawable.soft_drink,
        label = "Soft Drink",
        price = 1.5
    ),
    SaleItemUiModel(
        id = "00019",
        imageResource = R.drawable.tacos,
        label = "Tacos",
        price = 6.5
    ),
    SaleItemUiModel(
        id = "00020",
        imageResource = R.drawable.veggies,
        label = "Veggie Plate",
        price = 7.5
    )
)

val demoOrderItems = listOf(
    OrderItemUiModel(
        name = "Fries",
        price = "$3.99"
    ),
    OrderItemUiModel(
        name = "Burger",
        price = "$4.20"
    ),
    OrderItemUiModel(
        name = "Milkshake",
        price = "$1.50"
    ),
    OrderItemUiModel(
        name = "Hot Dog",
        price = "$9.00"
    )
)

val demoTicketItems = listOf(
    TicketItemUi(
        time = "9:59 AM",
        shortOrderId = "e893j3",
        items = hashMapOf(
            "Burger" to 1,
            "Coffee" to 1,
            "Milk" to 3
        ),
        isPaid = true,
        orderStatus = OrderStatus.PROCESSED,
        orderId = ""
    ),
    TicketItemUi(
        time = "4:29 PM",
        shortOrderId = "08n3iuo48",
        items = hashMapOf(
            "Fruit Salad" to 2,
            "Coffee" to 1,
            "Corn" to 1,
            "Cereal" to 5
        ),
        isPaid = false,
        orderStatus = OrderStatus.IN_PROCESS,
        orderId = ""
    )
)

val demoLocations = listOf(
    Location(
        id = "00001",
        name = "Ham's Burgers"
    ),
    Location(
        id = "00002",
        name = "Sally's Salad Bar"
    ),
    Location(
        id = "00003",
        name = "Kyle's Kabobs"
    ),
    Location(
        id = "00004",
        name = "Frank's Falafels"
    ),
    Location(
        id = "00005",
        name = "Cathy's Crepes"
    ),
    Location(
        id = "00006",
        name = "Gilbert's Gumbo"
    ),
    Location(
        id = "00007",
        name = "Tarra's Tacos"
    )
)
