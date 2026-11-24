enum KitchenOrders {
    static let query = """
        SELECT * FROM \(Order.collectionName)
        WHERE _id.locationId = :locationId
            AND object_length(cart) > 0
        ORDER BY createdAt DESC, _id.id
        """

    static func active(from orders: [Order]) -> [Order] {
        orders.filter {
            let status = $0.status
            return status == .inProcess || status == .processed
        }
    }
}
