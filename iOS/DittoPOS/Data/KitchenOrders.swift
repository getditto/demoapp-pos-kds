enum KitchenOrders {
    // A stale transition must not reopen a more advanced or terminal ticket.
    // https://docs.ditto.live/best-practices/conflict-resolution-patterns
    static let query = """
        SELECT * FROM \(Order.collectionName)
        WHERE _id.locationId = :locationId
            AND object_length(cart) > 0
            AND (
                array_contains(object_values(status_log), 'inProcess')
                OR array_contains(object_values(status_log), 'processed')
            )
            AND NOT array_contains(object_values(status_log), 'delivered')
            AND NOT array_contains(object_values(status_log), 'canceled')
        ORDER BY array_contains(object_values(status_log), 'processed'), createdAt DESC, _id.id
        """
}
