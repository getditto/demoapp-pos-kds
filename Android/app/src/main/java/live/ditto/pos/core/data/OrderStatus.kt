package live.ditto.pos.core.data

enum class OrderStatus(title: String) {
    OPEN("open"),
    IN_PROCESS("inProcess"),
    PROCESSED("processed"),
    DELIVERED("delivered"),
    CANCELED("canceled")
}